require_relative "debuggable"

# @example
#   class APIContract < BaseContract
#     guarantee :existing_data do |api_call|
#       !api_call.response.code.empty? &&
#         !api_call.response.data.empty?
#     end
#
#     expect :success do |api_call|
#       next unless api_call.response.success?
#
#       # dynamic nested rule for stats
#       expect api_call.response.city { |_| true }
#     end
#
#     expect :failure do |api_call|
#       api_call.response.failure?
#     end
#
#     expect_error :timeout do |api_call|
#       api_call.error.key?(Timout::Error)
#     end
#
#     statistics_guarantee :failure, limit: "30%" # of stats period batch
#   end
module BloodContracts
  module Contracts
    module DSL
      using StringPathize
      using StringCamelcase
      DEFAULT_TAG = :default

      attr_reader :expectations_rules, :guarantees_rules,
                  :statistics_guarantees, :rules_cache
      def inherited(child_klass)
        child_klass.instance_variable_set(:@expectations_rules, Set.new)
        child_klass.instance_variable_set(:@guarantees_rules, Set.new)
        child_klass.instance_variable_set(:@statistics_guarantees, {})
        child_klass.instance_variable_set(:@rules_cache, {})
      end

      class BaseRule < Delegator
        class << self
          attr_accessor :contract, :tag

          def inherited(child_klass)
            child_klass.instance_variable_set(:@contract, contract)
          end

          def full_name
            name
              .gsub(/#{contract.name}::/, "")
              .pathize
              .gsub(/expectation_|guarantee_/, "")
          end

          def to_h
            stats_requirements = contract.statistics_guarantees[full_name].to_h
            stats_requirements.merge!(check: self)
          end

          def call(round)
            rule_stack = []
            new.tap { |rule| rule_stack << rule.call(round) }
               .tap { |rule| rule_stack.push(*rule.children) }
            rule_stack
          end
        end

        attr_reader :children
        def initialize
          @children = []
        end

        def to_h
          self.class.to_h
        end

        NO_NAME_RULE = "empty_rule_name".freeze

        def register_rule(name, prefix, tag)
          name = name.to_s
          name = NO_NAME_RULE if name.empty?
          rule = contract.rules_cache.fetch(File.join(full_name, name)) do
            create_sub_rule(name, prefix).tap do |new_rule|
              after_sub_rule_create(new_rule, tag)
              yield(new_rule)
            end
          end
          children << [rule.full_name.to_sym, rule.to_h]
          true
        end

        def after_sub_rule_create(new_rule, tag)
          new_rule.tag = tag
          contract.update_tags(new_rule.full_name, tag)
        end

        def create_sub_rule(name, prefix)
          new_rule = Class.new(self.class)
          self.class.const_set(new_rule_name(prefix, name), new_rule)
          contract.rules_cache.store(new_rule.full_name, new_rule)
          new_rule
        end

        def full_name
          self.class.full_name
        end

        def contract
          self.class.contract
        end
        alias :__getobj__ :contract
      end

      class ExpectationRule < BaseRule
        def expectation_rule(name, tag: self.class.tag, &block)
          register_rule(name, "expectation", tag) do |new_rule|
            new_rule.send(:define_method, :call, &block)
          end
        end
        alias :expect :expectation_rule

        def self.call(round)
          return [false] if round.error?
          super
        end
      end

      class ErrorRule < BaseRule
        def expectation_error_rule(name, tag: self.class.tag, &block)
          register_rule(name, "expectation", tag) do |new_rule|
            new_rule.send(:define_method, :call, &block)
          end
        end
        alias :expect_error :expectation_error_rule

        def self.call(round)
          return [false] unless round.error?
          super
        end
      end

      class GuaranteeRule < BaseRule
        def guarantee_rule(name, tag: self.class.tag, &block)
          register_rule(name, "guarantee", tag) do |new_rule|
            new_rule.send(:define_method, :call, &block)
          end
        end
        alias :guarantee :guarantee_rule

        def self.call(round)
          return [true] if round.error?
          super
        end
      end

      def expectation_rule(name, tag: DEFAULT_TAG, &block)
        register_rule(ExpectationRule, "expectation", name, tag) do |new_rule|
          new_rule.send(:define_method, :call, &block)
          expectations_rules << name
        end
      end
      alias :expect :expectation_rule

      def expectation_error_rule(name, tag: DEFAULT_TAG, &block)
        register_rule(ErrorRule, "expectation", name, tag) do |new_rule|
          new_rule.send(:define_method, :call, &block)
          expectations_rules << name
        end
      end
      alias :expect_error :expectation_error_rule

      def guarantee_rule(name, tag: DEFAULT_TAG, &block)
        register_rule(GuaranteeRule, "guarantee", name, tag) do |new_rule|
          new_rule.send(:define_method, :call, &block)
          guarantees_rules << name
        end
      end
      alias :guarantee :guarantee_rule

      class UselessStatisticsRule < ArgumentError; end

      def statistics_guarantee(rule_name, limit: nil, threshold: nil)
        raise UselessStatisticsRule unless limit || threshold
        statistics_guarantees[rule_name] = {
          limit: limit, threshold: threshold
        }.compact
      end
      alias :statistics_rule :statistics_guarantee

      def update_tags(rule_name, tag)
        tags = BloodContracts.tags[name.pathize] || {}
        tags[rule_name.to_s] = Array(tag)
        BloodContracts.tags[name.pathize] = tags
      end

      def skip
        false
      end

      def new_rule_name(prefix, name)
        "#{prefix}_#{name}".gsub(/\W/, "_").camelcase(:upper)
      end

      private

      def register_rule(klass, prefix, name, tag)
        new_rule = Class.new(klass)
        new_rule.contract = self
        new_rule.tag = tag
        const_set(new_rule_name(prefix, name), new_rule)
        yield(new_rule)
        update_tags(name, tag)
      end
    end
  end
end

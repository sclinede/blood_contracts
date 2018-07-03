require_relative "debuggable"

# @example
#   class APIContract < BaseContract
#     guarantee :existing_data do |api_call|
#       !api_call.response.code.empty? &&
#         !api_call.response.data.empty?
#     end
#
#     expect :success do |api_call|
#       api_call.response.success?
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
      using ClassDescendants
      DEFAULT_TAG = :default

      attr_reader :expectations_rules, :guarantees_rules,
                  :statistics_guarantees, :rules_cache
      def inherited(child_klass)
        child_klass.instance_variable_set(:@expectations_rules, Set.new)
        child_klass.instance_variable_set(:@guarantees_rules, Set.new)
        child_klass.instance_variable_set(:@statistics_guarantees, {})
        child_klass.instance_variable_set(:@rules_cache, {})
      end

      # def expectation_rule(name, tag: DEFAULT_TAG, inherit: nil, &block)
      #   define_method("raw_check_#{name}", &block)
      #   define_method("expectation_#{name}") do |round|
      #     next if round.error?
      #     next(send("raw_check_#{name}", round)) unless !!inherit
      #     send("expectation_#{inherit}", round) && send("raw_check_#{name}", round)
      #   end
      #   expectations_rules << name
      #   update_tags(name, tag)
      # end
      # alias :expect :expectation_rule

      class BaseRule
        class << self
          attr_accessor :contract

          def inherited(child_klass)
            child_klass.instance_variable_set(:@contract, contract)
          end

          def full_name
            name
              .gsub(%r{#{contract.name}::}, '')
              .pathize
              .gsub(/expectation_|guarantee_/, '')
          end

          def to_h
            stats_requirements = contract.statistics_guarantees[full_name].to_h
            stats_requirements.merge!(check: self)
          end

          def call(round)
            rule_stack = []
            new.tap { |rule| rule_stack << rule.call(round) }
               .tap { |rule| rule_stack.push(*rule.children)  }
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

        def register_rule(name, prefix, tag)
          name = name.to_s
          rule = contract.rules_cache.fetch(File.join(full_name, name)) do
            create_sub_rule(name, prefix).tap do |new_rule|
              yield(new_rule)
              update_tags(new_rule.full_name, tag)
            end
          end
          self.children << [rule.full_name.to_sym, rule.to_h]
          true
        end

        def create_sub_rule(name, prefix)
          new_rule = Class.new(self.class)
          new_rule_name = "#{prefix}_#{name}".camelcase(:upper)
          self.class.const_set(new_rule_name, new_rule)
          contract.rules_cache.store(new_rule.full_name, new_rule)
          new_rule
        end

        def update_tags(rule_name, tag)
          tags = BloodContracts.tags[contract.name] || {}
          tags[rule_name.to_s] = Array(tag)
          BloodContracts.tags[contract.name] = tags
        end

        def full_name
          self.class.full_name
        end

        def contract
          self.class.contract
        end
      end

      class ExpectationRule < BaseRule
        def expectation_rule(name, tag: DEFAULT_TAG, &block)
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
        def expectation_error_rule(name, tag: DEFAULT_TAG, &block)
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
        def guarantee_rule(name, tag: DEFAULT_TAG, &block)
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

      # expect :one do |round1|
      #   next unless round1.response[:a]
      #
      #   expect :two do |round2|
      #     next unless round2.response[:b]
      #     true
      #   end
      #
      #   expect :three do |round3|
      #     next unless round3.response[:c]
      #     true
      #   end
      # end

      def expectation_rule(name, tag: DEFAULT_TAG, &block)
        register_rule(ExpectationRule, "expectation", name, tag) do |new_rule|
          new_rule.send(:define_method, :call, &block)
          expectations_rules << name
        end
      end
      alias :expect :expectation_rule

      def expectation_error_rule(name, tag: DEFAULT_TAG, inherit: nil, &block)
        register_rule(ErrorRule, "expectation", name, tag) do |new_rule|
          new_rule.send(:define_method, :call, &block)
          expectations_rules << name
        end
      end
      alias :expect_error :expectation_error_rule

      def guarantee_rule(name, tag: DEFAULT_TAG, skip_on_error: true, &block)
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

      private

      def register_rule(klass, prefix, name, tag)
        new_rule = Class.new(klass)
        new_rule.contract = self
        const_set("#{prefix}_#{name}".camelcase(:upper), new_rule)
        yield(new_rule)
        update_tags(name, tag)
      end

      def update_tags(rule_name, tag)
        tags = BloodContracts.tags[name.pathize] || {}
        tags[rule_name.to_s] = Array(tag)
        BloodContracts.tags[name.pathize] = tags
      end
    end
  end
end

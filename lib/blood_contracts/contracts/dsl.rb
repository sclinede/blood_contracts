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
      using StringCamelize
      using ClassDescendants
      DEFAULT_TAG = :default

      attr_reader :expectations_rules, :guarantees_rules, :statistics_guarantees
      def inherited(child_klass)
        child_klass.instance_variable_set(:@expectations_rules, Set.new)
        child_klass.instance_variable_set(:@guarantees_rules, Set.new)
        child_klass.instance_variable_set(:@statistics_guarantees, {})
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
          RESERVED_CLASSES = %w(ExpectationRule GuaranteeRule ErrorRule).freeze

          attr_accessor :parent, :children, :contract_name
          def inherited(child_klass)
            self.children = (children.to_a << child_klass)
            child_klass.instance_variable_set(:@contract_name, contract_name)
            return if self.superclass == BaseRule
            child_klass.instance_variable_set(:@parent, self)
          end

          def with_children
            ([self] + descendants).each
          end

          def call(round)
            return if parent && !parent.call(round)
            new.call(round)
          end

          def original_name
            name.pathize
              .gsub(%r{#{contract_name}/}, '')
              .gsub(/expectation_|guarantee_/, '')
          end
        end

        def update_tags(rule_name, tag)
          tags = BloodContracts.tags[self.class.contract_name] || {}
          tags[rule_name.to_s] = Array(tag)
          BloodContracts.tags[self.class.contract_name] = tags
        end
      end

      class ExpectationRule < BaseRule
        def expectation_rule(name, tag: DEFAULT_TAG, &block)
          new_rule = Class.new(self.class)
          new_rule.send(:define_method, :call, &block)
          self.class.remove_const("expectation_#{name}".camelcase(:upper))
          self.class.const_set("expectation_#{name}".camelcase(:upper), new_rule)
          update_tags(name, tag)
        end
        alias :expect :expectation_rule

        def self.call(round)
          return if round.error?
          super
        end
      end

      class ErrorRule < BaseRule
        def expectation_error_rule(name, tag: DEFAULT_TAG, &block)
          new_rule = Class.new(self.class)
          new_rule.send(:define_method, :call, &block)
          self.class.remove_const("expectation_#{name}".camelcase(:upper))
          self.class.const_set("expectation_#{name}".camelcase(:upper), new_rule)
          update_tags(name, tag)
        end
        alias :expect_error :expectation_error_rule

        def self.call(round)
          return unless round.error?
          super
        end
      end

      class GuaranteeRule < BaseRule
        def guarantee_rule(name, tag: DEFAULT_TAG, &block)
          new_rule = Class.new(self.class)
          new_rule.send(:define_method, :call, &block)
          self.class.remove_const("guarantee_#{name}".camelcase(:upper))
          self.class.const_set("guarantee_#{name}".camelcase(:upper), new_rule)
          update_tags(name, tag)
        end
        alias :guarantee :guarantee_rule
      end

      # test_rule :one do |round1|
      #   next unless round1.response[:a]
      #
      #   test_rule :two do |round2|
      #     next unless round2.response[:b]
      #     true
      #   end
      #
      #   test_rule :three do |round3|
      #     next unless round3.response[:c]
      #     true
      #   end
      # end

      def expectation_rule(name, tag: DEFAULT_TAG, &block)
        new_rule = Class.new(ExpectationRule)
        new_rule.contract_name = self.name.pathize
        new_rule.send(:define_method, :call, &block)
        const_set("expectation_#{name}".camelcase(:upper), new_rule)
        expectations_rules << name
        update_tags(name, tag)
      end
      alias :expect :expectation_rule

      def expectation_error_rule(name, tag: DEFAULT_TAG, inherit: nil, &block)
        new_rule = Class.new(ErrorRule)
        new_rule.contract_name = self.name.pathize
        new_rule.send(:define_method, :call, &block)
        const_set("expectation_#{name}".camelcase(:upper), new_rule)
        expectations_rules << name
        update_tags(name, tag)
      end
      alias :expect_error :expectation_error_rule

      def guarantee_rule(name, tag: DEFAULT_TAG, skip_on_error: true, &block)
        new_rule = Class.new(GuaranteeRule)
        new_rule.contract_name = self.name.pathize
        new_rule.send(:define_method, :call, &block)
        const_set("guarantee_#{name}".camelcase(:upper), new_rule)
        guarantees_rules << name
        update_tags(name, tag)
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

      def update_tags(rule_name, tag)
        tags = BloodContracts.tags[name.pathize] || {}
        tags[rule_name.to_s] = Array(tag)
        BloodContracts.tags[name.pathize] = tags
      end
    end
  end
end

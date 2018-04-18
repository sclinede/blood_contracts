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
#     expect_statistics :failure, limit: "30%" # of stats period batch
#   end
module BloodContracts
  module Contracts
    module DSL
      using StringPathize
      DEFAULT_TAG = :default

      attr_reader :expectations_rules, :guarantees_rules, :statistics_rules
      def inherited(child_klass)
        child_klass.instance_variable_set(:@expectations_rules, Set.new)
        child_klass.instance_variable_set(:@guarantees_rules, Set.new)
        child_klass.instance_variable_set(:@statistics_rules, {})
        # TODO: add helper to include Debugger, but no need to run it all the
        # time
        # child_klass.prepend Debuggable
      end

      def expectation_rule(name, tag: DEFAULT_TAG, inherit: nil, &block)
        if inherit
          define_method("expectation_#{name}") do |round|
            send("expectation_#{inherit}", round) && yield(round)
          end
        else
          define_method("expectation_#{name}", &block)
        end
        expectations_rules << name
        update_tags(name, tag)
      end
      alias :expect :expectation_rule

      def guarantee_rule(name, tag: DEFAULT_TAG, &block)
        define_method("guarantee_#{name}", &block)
        guarantees_rules << name
        update_tags(name, tag)
      end
      alias :guarantee :guarantee_rule

      class UselessStatisticsRule < ArgumentError; end

      def statistics_rule(rule_name, limit: nil, threshold: nil)
        raise UselessStatisticsRule unless limit || threshold
        statistics_rules[rule_name] = {
          limit: limit, threshold: threshold
        }.compact
      end
      alias :expect_statistics :statistics_rule

      private

      def update_tags(rule_name, tag)
        tags = BloodContracts.tags[name.pathize] || {}
        tags[rule_name.to_s] = Array(tag)
        BloodContracts.tags[name.pathize] = tags
      end
    end
  end
end

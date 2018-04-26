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
      DEFAULT_TAG = :default

      attr_reader :expectations_rules, :guarantees_rules, :statistics_guarantees
      def inherited(child_klass)
        child_klass.instance_variable_set(:@expectations_rules, Set.new)
        child_klass.instance_variable_set(:@guarantees_rules, Set.new)
        child_klass.instance_variable_set(:@statistics_guarantees, {})
      end

      def expectation_rule(name, tag: DEFAULT_TAG, inherit: nil)
        define_method("expectation_#{name}") do |round|
          next if round.error?
          next(yield(round)) unless !!inherit
          send("expectation_#{inherit}", round) && yield(round)
        end
        expectations_rules << name
        update_tags(name, tag)
      end
      alias :expect :expectation_rule

      def expectation_error_rule(name, tag: DEFAULT_TAG, inherit: nil)
        define_method("expectation_#{name}") do |round|
          next unless round.error?
          next(yield(round)) unless !!inherit
          send("expectation_#{inherit}", round) && yield(round)
        end
        expectations_rules << name
        update_tags(name, tag)
      end
      alias :expect_error :expectation_error_rule

      def guarantee_rule(name, tag: DEFAULT_TAG, skip_on_error: true)
        define_method("guarantee_#{name}") do |round|
          next(true) if skip_on_error && round.error?
          yield(round)
        end
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

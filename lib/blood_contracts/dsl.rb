require_relative "concerns/debuggable"

module BloodContracts
  module DSL
    using StringPathize
    DEFAULT_TAG = :default

    attr_reader :rules, :statistics_rules
    def inherited(child_klass)
      child_klass.instance_variable_set(:@rules, Set.new)
      child_klass.instance_variable_set(:@statistics_rules, Hash.new)
      child_klass.prepend Concerns::Debuggable
    end

    def tag(config)
      tags = BloodContracts.config.tags[name.pathize] || {}
      config.each_pair do |tag, rules|
        rules.each { |rule| tags[rule.to_s] ||= tag.to_s }
      end
      BloodContracts.config.tags[name.pathize] = tags
    end

    def contract_rule(name, tag: DEFAULT_TAG, &block)
      define_method("_#{name}", &block)
      rules << name

      tags = BloodContracts.config.tags[self.name.pathize] || {}
      tags[name.to_s] = tag
      BloodContracts.config.tags[self.name.pathize] = tags
    end

    class UselessStatisticsRule < ArgumentError; end

    def statistics(rule_name, limit: nil, threshold: nil)
      raise UselessStatisticsRule unless limit || threshold
      statistics_rules[rule_name] = {limit: limit, threshold: threshold}.compact
    end
  end
end
#
# @example
#   class APIContract < BaseContract
#     contract_rule :success do |api_call|
#       api_call.response.success?
#     end
#
#     contract_rule :failure do |api_call|
#       api_call.response.failure?
#     end
#
#     statistics :failure, limit: "10%" # of sampling batch
#   end
#
#
#
#

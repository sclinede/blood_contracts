module BloodContracts
  module Storages
    class Redis < Base
      class Statistics
        attr_reader :contract_name, :statistics, :redis
        def initialize(base_storage, redis, statistics)
          @contract_name = base_storage.contract_name
          @redis = redis
          @statistics = statistics
        end

        def delete_all
          keys_to_delete = redis.keys(period_rules_key("*"))
          keys_to_delete |= redis.keys(counter_key("*", "*"))
          keys_to_delete |= [periods_key]
          redis.del(*keys_to_delete)
        end

        def delete(period)
          keys_to_delete = redis.keys(period_rules_key(period))
          keys_to_delete |= redis.keys(counter_key(period, "*"))
          redis.del(*keys_to_delete)
          remove_period_from_set(period)
        end

        def increment(rule, period = statistics.current_period)
          prepare_storage(period, rule)
          redis.incr(counter_key(period, rule))
        end

        def filter(*periods)
          stats = periods.map { |period| period_rules_counters(period) }
          dates = periods.map do |period_int|
            Time.at(period_int * statistics.period_size)
          end
          Hash[dates.zip(stats)]
        end

        def total
          Hash[
            periods
            .sort_by { |(period_int, _)| -period_int }
            .map do |period|
              [
                Time.at(period * statistics.period_size),
                period_rules_counters(period)
              ]
            end
          ]
        end

        private

        def counter(a_counter_key = nil, period: nil, rule: nil)
          redis.get(a_counter_key || counter_key(period, rule)).to_i
        end

        def period_rules_counters(period)
          Hash[
            period_rules(period).map do |counter_key, rule|
              [rule, counter(counter_key)]
            end
          ]
        end

        def period_rules(period)
          values = redis.smembers(period_rules_key(period))
          values.nil? ? [] : values.map { |v| Oj.load(v) }
        end

        def periods_key
          "blood_contracts:contract-#{contract_name}:statistics:periods"
        end

        def period_rules_key(period)
          "blood_contracts:contract-#{contract_name}"\
          ":statistics:period-#{period}"
        end

        def counter_key(period, rule)
          "blood_contracts:contract-#{contract_name}"\
          ":statistics:period-#{period}:rule-#{rule}:counter"
        end

        def prepare_storage(period, rule)
          add_period_to_set(period)
          add_period_rule_to_set(period, rule)
        end

        def add_period_rule_to_set(period, rule)
          rule_key = period_rules_key(period)
          counter_key = counter_key(period, rule)
          redis.sadd(rule_key, Oj.dump([counter_key, rule]))
        end

        def periods(conn = nil)
          conn ||= redis
          values = conn.smembers(periods_key)
          values = values.value if values.is_a?(::Redis::Future)
          values.nil? ? [] : values.map { |v| Oj.load(v) }
        end

        def add_period_to_set(period, conn = nil)
          conn ||= redis
          conn.sadd(periods_key, Oj.dump(period))
        end

        def remove_period_from_set(period, conn = nil)
          conn ||= redis
          conn.srem(periods_key, Oj.dump(period))
        end
      end
    end
  end
end

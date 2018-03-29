module BloodContracts
  module Concerns
    module DSL
      DEFAULT_TAG = :default

      attr_reader :rules
      def inherited(child_klass)
        child_klass.instance_variable_set(:@rules, Set.new)
      end

      def tag(config)
        tags = BloodContracts.config.tags[to_s.pathize] || {}
        config.each_pair do |tag, rules|
          rules.each { |rule| tags[rule.to_s] ||= tag.to_s }
        end
        BloodContracts.config.tags[to_s.pathize] = tags
      end

      def contract_rule(name, tag: DEFAULT_TAG, &block)
        define_method("_#{name}", &block)
        rules << name

        tags = BloodContracts.config.tags[to_s.pathize] || {}
        tags[name.to_s] = tag
        BloodContracts.config.tags[to_s.pathize] = tags
      end

      def apply_to(klass:, methods:, override: false)
        contract_accessor = "#{self.to_s.downcase.gsub(/\W/, '_')}_contract"
        if klass.instance_methods.include?(contract_accessor) && !override
          return warn <<~WARNING
            WARNING! Class #{klass} already has a contract assigned.
            Skipping #{self}#apply_to(...) at #{caller[0]}.\n
          WARNING
        end

        patch = Module.new do
          def contract(klass)
            send("#{klass.to_s.downcase.gsub(/\W/, '_')}_contract")
          end
        end

        patch.module_eval <<~CODE
          def #{contract_accessor}
            @#{contract_accessor} ||= #{self}.new
          end

          %i(#{Array(methods).join(',')}).each do |method_name|
            define_method(method_name) do |*args, **kwargs|
              #{contract_accessor}.call(*args, **kwargs) do
                super(*args, **kwargs)
              end
            end
          end
        CODE

        klass.prepend patch
      end
    end
  end
end

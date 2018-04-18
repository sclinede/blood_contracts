module BloodContracts
  module Contracts
    module Patching
      def apply_to(klass:, methods:, override: false)
        contract_accessor = to_s.downcase.gsub(/\W/, "_")
        methods = Array(methods).join(",")
        contract_accessor_exists =
          klass.instance_methods.include?(contract_accessor.to_sym)

        if contract_accessor_exists && !override
          return warn_about_contract_duplication(klass, caller(1..1).first)
        end

        klass.prepend contract_patch_module(contract_accessor, methods)
      end

      private

      def warn_about_contract_duplication(klass, kaller)
        warn <<~WARNING
          WARNING! Class #{klass} already has a contract assigned.
          Skipping #{self}#apply_to(...) at #{kaller}.\n
        WARNING
      end

      # rubocop:disable Metrics/MethodLength
      def contract_patch_module(accessor, methods)
        patch = Module.new do
          def find_contract(klass)
            send(klass.to_s.downcase.gsub(/\W/, "_"))
          end
        end
        patch.module_eval(
          format(
            PATCH_TEMPLATE, accessor: accessor, contract: to_s, methods: methods
          ), __FILE__, __LINE__ + 1
        )
        patch
      end
      # rubocop:enable Metrics/MethodLength

      # rubocop:disable Style/FormatStringToken
      PATCH_TEMPLATE = <<~CODE.freeze
        def %{accessor}
          @%{accessor} ||= %{contract}.new
        end

        %%i(%{methods}).each do |method_name|
          define_method(method_name) do |*args, **kwargs|
            %{accessor}.call(*args, **kwargs) do
              if kwargs.empty?
                super(*args)
              else
                super(*args, **kwargs)
              end
            end
          end
        end
      CODE
      # rubocop:enable Style/FormatStringToken
    end
  end
end

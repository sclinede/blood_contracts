module BloodContracts
  module Contracts
    class Status
      extend Dry::Initializer
      extend Forwardable
      param :contract

      def_delegators :contract, :contract_hash, :sampler, :statistics

      # FIXME: Move to locales?
      def failure_message
        intro = "expected that given Proc would meet the contract:"
        "#{intro}\n#{contract_description}\n#{statistics}"\
        "For further investigations check storage (#{sampler.storage.class}): "\
        "#{suggestion}"
      end

      # FIXME: Move to locales?
      def description
        "meet the contract:\n#{contract_description} \n#{statistics}"\
        "For further investigations check storage (#{sampler.storage.class}): "\
        "#{suggestion}\n"
      end
      alias :to_s :description

      def contract_description
        Contracts::Description.call(contract_hash)
      end

      def suggestion
        if statistics.found_unexpected_behavior?
          "[session_name=#{sampler.session},"\
          "rule=#{BloodContracts::UNEXPECTED_BEHAVIOR}]"
        else
          "[session_name=#{sampler.session}}]"
        end
      end
    end
  end
end

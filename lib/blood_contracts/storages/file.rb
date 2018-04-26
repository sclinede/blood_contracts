require_relative "file/sampling"

module BloodContracts
  module Storages
    class File < Base
      def init
        FileUtils.mkdir_p(
          ::File.join(
            BloodContracts.sampling_config.dig(:storage, :root),
            "blood_samples",
            session
          )
        )
      end

      def sampling(sampler)
        Sampling.new(session, contract_name, sampler)
      end

      def statistics(*)
        raise NotImplementedError
      end

      def switching(*)
        raise NotImplementedError
      end
    end
  end
end

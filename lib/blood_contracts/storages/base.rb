require "nanoid"
require_relative "base/sampling.rb"
require_relative "base/switching.rb"
require_relative "base/statistics.rb"

module BloodContracts
  module Storages
    class Base
      extend Dry::Initializer
      extend Forwardable

      param :contract_name
      option :session, default: -> do
        BloodContracts.session_name || ::Nanoid.generate(size: 10)
      end

      def init; end

      def sampling(_sampler)
        Sampling.new
      end

      def statistics(_statistics)
        Statistics.new
      end

      def switching(_switcher)
        Switching.new
      end
    end
  end
end

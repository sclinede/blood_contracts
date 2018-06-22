module BloodContracts
  module Samplers
    module PreviewersAccessors
      DEFAULT_INPUT_PREVIEWER = ->(round) { "INPUT:\n#{round.input}" }
      DEFAULT_OUTPUT_PREVIEWER = ->(round) { "OUTPUT:\n#{round.output}" }

      def self.included(klass)
        klass.option :input_previewer, ->(v) { Previewer.call(v) },
                     default: -> { DEFAULT_INPUT_PREVIEWER }

        klass.option :output_previewer, ->(v) { Previewer.call(v) },
                     default: -> { DEFAULT_OUTPUT_PREVIEWER }
      end

      class Previewer
        def self.call(previewer)
          return previewer if previewer.respond_to?(:call) ||
                              previewer.respond_to?(:to_sym)
          raise ArgumentError
        end
      end

      def input_previewer=(previewer)
        @input_previewer = Previewer.call(previewer)
      end

      def output_previewer=(previewer)
        @output_previewer = Previewer.call(previewer)
      end
    end
  end
end

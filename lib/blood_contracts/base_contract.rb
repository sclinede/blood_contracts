require_relative "./concerns/dsl.rb"

module BloodContracts
  class BaseContract
    extend Concerns::DSL

    def enable!
      Thread.current[to_s.pathize] = true
    end

    def disable!
      Thread.current[to_s.pathize] = false
    end

    def enabled?
      if Thread.current[to_s.pathize].nil?
        Thread.current[to_s.pathize] = BloodContracts.config.enabled
      end
      !!Thread.current[to_s.pathize]
    end

    def action
      @action ||= action_proc || object.method(method_name)
    end

    def runner
      @runner ||= Runner.new(context: self, suite: to_contract_suite)
    end

    def before_runner(args:, kwargs:, output:, error:, meta:); end
    def before_call(args:, kwargs:, meta:); end

    def call(*args, **kwargs)
      return yield unless enabled?

      output, meta, error = "", {}, nil
      before_call(args: args, kwargs: kwargs, meta: meta)

      begin
        output = yield(meta)
      rescue StandardError => exception
        error = exception
        raise error
      ensure
        before_runner(
          args: args, kwargs: kwargs, output: output, meta: meta, error: error
        )
        runner.call(
          args: args, kwargs: kwargs, output: output, meta: meta, error: error
        )
      end
    end

    def contract
      @contract ||= Hash[
        self.class.rules.map { |name| [name, { check: method("_#{name}") }] }
      ]
    end

    def build_storage(name)
      s = Storage.new(contract_name: name)

      s.input_writer  = method(:input_writer)    if defined? input_writer
      s.input_writer  = method(:request_writer)  if defined? request_writer
      s.output_writer = method(:output_writer)   if defined? output_writer
      s.output_writer = method(:response_writer) if defined? response_writer

      s.input_serializer  = request_serializer if defined? request_serializer
      s.input_serializer  = input_serializer   if defined? input_serializer
      s.output_serializer = output_serializer  if defined? output_serializer
      s.output_serializer = response_serializer if defined? response_serializer

      s.meta_serializer   = meta_serializer if defined? meta_serializer
      s
    end

    def to_contract_suite(name: self.class.to_s.pathize)
      Suite.new(storage: build_storage(name), contract: contract)
    end
  end
end

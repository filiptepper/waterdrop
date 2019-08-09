# frozen_string_literal: true

module WaterDrop
  # Main WaterDrop messages producer
  class Producer
    include Sync
    include Async
    include Buffer

    attr_reader :status

    # Creates a not-yet-configured instance of the producer
    # @return [WaterDrop::Producer] producer instance
    def initialize
      @status = Status.new
      @buffer = Concurrent::Array.new
      @mutex = Mutex.new
      @contract = Contracts::Message.new
      @validator = method(:validate_message!)
    end

    # Sets up the whole configuration and initializes all that is needed
    # @note When using forked process such as when using Unicorn you currently need to make sure
    #   that you run the setup after forking.
    #
    # @param block [Block] configuration block
    def setup(&block)
      @config = Config
                .new
                .setup(&block)
                .config

      @monitor = @config.monitor
      @client = Builder.new.call(self, @config)
      @status.active!
    end

    # Flushes the buffers in a sync way and closes the producer
    def close
      return unless @status.active?

      @status.closing!

      flush(false)

      @client.close
      @status.closed!
    end

    private

    # Ensures that we don't run any operations when the producer is not configured or when it
    # was already closed
    def ensure_active!
      return if @status.active?

      raise Errors::ProducerNotConfiguredError if @status.initial?
      raise Errors::ProducerClosedError if @status.closing? || @status.closed?

      raise Errors::InvalidStatusError, @status.to_s
    end

    def validate_message!(message)
      result = @contract.call(message)
      return if result.success?

      raise Errors::InvalidMessageError, [
        result.errors.to_h,
        message
      ]
    end
  end
end
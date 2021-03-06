# frozen_string_literal: true

RSpec.describe WaterDrop::Message do
  subject(:waterdrop_message) { described_class.new(topic, message) }

  let(:topic) { double }
  let(:message) { [] }
  let(:producer) { double }

  describe '#send!' do
    let(:message_producer) { double }
    let(:messages) { double }

    context 'when everything is ok' do
      let(:config) { double }

      before do
        allow(WaterDrop).to receive(:config).and_return(config)
        allow(config).to receive(:send_messages).and_return(true)
      end

      it 'sends message with topic and message' do
        expect(WaterDrop::Pool).to receive(:with).and_yield(producer)
        expect(producer).to receive(:send_message).with(any_args)
        waterdrop_message.send!
      end
    end

    [StandardError].each do |error|
      let(:config) do
        WaterDrop::Config.config.tap do |config|
          config.raise_on_failure = raise_on_failure
          config.send_messages = true
        end
      end

      context "when #{error} happens" do
        context 'and raise_on_failure is set to false' do
          let(:raise_on_failure) { false }

          it 'expect not to raise error' do
            expect(::WaterDrop).to receive(:config).and_return(config).exactly(2).times
            expect(::WaterDrop::Pool).to receive(:with).and_raise(error)
            expect { waterdrop_message.send! }.not_to raise_error
          end
        end

        context 'and raise_on_failure is set to true' do
          let(:raise_on_failure) { true }

          it 'expect not to raise error' do
            expect(::WaterDrop).to receive(:config).and_return(config).exactly(2).times
            expect(::WaterDrop::Pool).to receive(:with).and_raise(error)
            expect { waterdrop_message.send! }.to raise_error
          end
        end
      end
    end
  end
end

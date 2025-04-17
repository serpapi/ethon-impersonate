# frozen_string_literal: true
require 'spec_helper'

describe EthonImpersonate::Curl do
  describe ".init" do
    before { EthonImpersonate::Curl.send(:class_variable_set, :@@initialized, false) }

    context "when global_init fails" do
      it "raises global init error" do
        expect(EthonImpersonate::Curl).to receive(:global_init).and_return(1)
        expect{ EthonImpersonate::Curl.init }.to raise_error(EthonImpersonate::Errors::GlobalInit)
      end
    end

    context "when global_init works" do
      before { expect(EthonImpersonate::Curl).to receive(:global_init).and_return(0) }

      it "doesn't raises global init error" do
        expect{ EthonImpersonate::Curl.init }.to_not raise_error
      end

      it "logs" do
        expect(EthonImpersonate.logger).to receive(:debug)
        EthonImpersonate::Curl.init
      end
    end

    context "when global_cleanup is called" do
      before { expect(EthonImpersonate::Curl).to receive(:global_cleanup) }

      it "logs" do
        expect(EthonImpersonate.logger).to receive(:debug).twice
        EthonImpersonate::Curl.init
        EthonImpersonate::Curl.cleanup
      end
    end
  end
end

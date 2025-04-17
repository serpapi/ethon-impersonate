# frozen_string_literal: true
require "spec_helper"

describe EthonImpersonate::Loggable do

  describe "#logger=" do

    let(:logger) do
      Logger.new($stdout).tap do |log|
        log.level = Logger::INFO
      end
    end

    before do
      EthonImpersonate.logger = logger
    end

    it "sets the logger" do
      expect(EthonImpersonate.logger).to eq(logger)
    end
  end
end

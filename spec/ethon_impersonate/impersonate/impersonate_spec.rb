# frozen_string_literal: true
require 'spec_helper'

describe EthonImpersonate::Easy do
  let(:easy) { EthonImpersonate::Easy.new }

  describe "#impersonate" do
    it "returns 0 for a target supported by the loaded library" do
      expect(easy.impersonate("chrome142")).to eq(0)
    end

    it "raises InvalidImpersonateTarget for an unknown versioned target" do
      expect { easy.impersonate("chrome1") }.to raise_error(
        EthonImpersonate::Errors::InvalidImpersonateTarget, /chrome1/
      )
    end

    it "is rescuable as ImpersonateFailed and EthonImpersonateError" do
      expect { easy.impersonate("unknown") }.to raise_error(EthonImpersonate::Errors::ImpersonateFailed)
      expect { easy.impersonate("unknown") }.to raise_error(EthonImpersonate::Errors::EthonImpersonateError)
    end
  end
end

# frozen_string_literal: true
require 'spec_helper'

describe EthonImpersonate::Libc do
  describe "#getdtablesize", if: !EthonImpersonate::Curl.windows? do
    it "returns an integer" do
      expect(EthonImpersonate::Libc.getdtablesize).to be_a(Integer)
    end

    it "returns bigger zero", if: !EthonImpersonate::Curl.windows? do
      expect(EthonImpersonate::Libc.getdtablesize).to_not be_zero
    end
  end
end

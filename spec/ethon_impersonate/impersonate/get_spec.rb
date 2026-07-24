# frozen_string_literal: true
require 'spec_helper'

describe "Impersonate" do
  let(:easy) { EthonImpersonate::Easy.new }
  let(:url) { "http://localhost:3001/" }
  let(:params) { nil }
  let(:form) { nil }
  let(:options) { {} }
  let(:get) { EthonImpersonate::Easy::Http::Get.new(url, {params: params, body: form}.merge(options)) }

  context "when requesting" do
    context "browser impersonation" do
      let(:url) { "https://httpbin.org/headers" }

      it "sets default headers with impersonation" do
        get.setup(easy)
        easy.impersonate("chrome142")
        easy.perform
        response = JSON.parse(easy.response_body)
        expect(response["headers"]).to include("User-Agent")
        expect(response["headers"]["User-Agent"]).to include("Chrome/142.0.0.0")
      end

      it "sets no headers when default_headers is false" do
        get.setup(easy)
        easy.impersonate("chrome142", default_headers: false)
        easy.perform
        response = JSON.parse(easy.response_body)
        expect(response["headers"]).not_to include("User-Agent")
      end

      it "raises error for unknown browser" do
        get.setup(easy)
        expect { easy.impersonate("unknown") }.to raise_error(
          EthonImpersonate::Errors::InvalidImpersonateTarget, /unknown/
        )
      end
    end
  end
end

# frozen_string_literal: true
require 'spec_helper'

describe "Impersonate" do
  let(:easy) { Ethon::Easy.new }
  let(:url) { "http://localhost:3001/" }
  let(:params) { nil }
  let(:form) { nil }
  let(:options) { {} }
  let(:get) { Ethon::Easy::Http::Get.new(url, {params: params, body: form}.merge(options)) }

  context "when requesting" do
    context "browser impersonation" do
      let(:url) { "https://postman-echo.com/headers" }

      it "sets default headers with impersonation" do
        get.setup(easy)
        easy.impersonate("chrome110")
        easy.perform
        response = JSON.parse(easy.response_body)
        expect(response["headers"]).to include("user-agent")
        expect(response["headers"]["user-agent"]).to include("Chrome/110.0.0.0")
      end

      it "sets no headers when default_headers is false" do
        get.setup(easy)
        easy.impersonate("chrome110", default_headers: false)
        easy.perform
        response = JSON.parse(easy.response_body)
        expect(response["headers"]).not_to include("user-agent")
      end

      it "raises error for unknown browser" do
        get.setup(easy)
        expect { easy.impersonate("unknown") }.to raise_error("Invalid impersonation target: 'unknown'")
      end
    end
  end
end

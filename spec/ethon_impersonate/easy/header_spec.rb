# frozen_string_literal: true
require 'spec_helper'

describe EthonImpersonate::Easy::Header do
  let(:easy) { EthonImpersonate::Easy.new }

  describe "#headers=" do
    let(:headers) { { 'User-Agent' => 'EthonImpersonate' } }

    it "sets header" do
      expect_any_instance_of(EthonImpersonate::Easy).to receive(:set_callbacks)
      expect(EthonImpersonate::Curl).to receive(:set_option)
      easy.headers = headers
    end

    context "when requesting" do
      before do
        easy.headers = headers
        easy.url = "http://localhost:3001"
        easy.perform
      end

      it "sends" do
        expect(easy.response_body).to include('"HTTP_USER_AGENT":"EthonImpersonate"')
      end

      context "when header value contains null byte" do
        let(:headers) { { 'User-Agent' => "EthonImpersonate\0" } }

        it "escapes" do
          expect(easy.response_body).to include('"HTTP_USER_AGENT":"EthonImpersonate\\\\0"')
        end
      end

      context "when header value has leading whitespace" do
        let(:headers) { { 'User-Agent' => " EthonImpersonate" } }

        it "removes" do
          expect(easy.response_body).to include('"HTTP_USER_AGENT":"EthonImpersonate"')
        end
      end

      context "when header value has trailing whitespace" do
        let(:headers) { { 'User-Agent' => "EthonImpersonate " } }

        it "removes" do
          expect(easy.response_body).to include('"HTTP_USER_AGENT":"EthonImpersonate"')
        end
      end

      context "when header value is an array" do
        let(:headers) { { 'X-Custom' => ['Example-1', 'Example-2'] } }

        it "sends" do
          expect(easy.response_body).to include('"HTTP_X_CUSTOM":"Example-1, Example-2"')
        end
      end
    end
  end

  describe "#compose_header" do
    it "has space in between" do
      expect(easy.compose_header('a', 'b')).to eq('a: b')
    end

    context "when value is a symbol" do
      it "works" do
        expect{ easy.compose_header('a', :b) }.to_not raise_error
      end
    end
  end

  describe "#header_list" do
    context "when no set_headers" do
      it "returns nil" do
        expect(easy.header_list).to eq(nil)
      end
    end

    context "when set_headers" do
      it "returns pointer to header list" do
        easy.headers = {'User-Agent' => 'Custom'}
        expect(easy.header_list).to be_a(FFI::Pointer)
      end
    end
  end
end

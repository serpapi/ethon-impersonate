# frozen_string_literal: true
require 'spec_helper'

describe EthonImpersonate::Impersonate::Settings do
  describe ".vendor_lib_dir" do
    it "uses ETHON_IMPERSONATE_VENDOR_DIR when set" do
      stub_const("ENV", ENV.to_h.merge("ETHON_IMPERSONATE_VENDOR_DIR" => "/custom/dir"))

      expect(described_class.vendor_lib_dir).to eq("/custom/dir")
    end

    it "appends vendor/curl-impersonate to the app root" do
      allow(described_class).to receive(:app_root).and_return("/my/app")

      expect(described_class.vendor_lib_dir).to eq("/my/app/vendor/curl-impersonate")
    end
  end

  describe ".app_root" do
    it "prefers Rails.root when available" do
      stub_const("Rails", double(root: Pathname.new("/rails/app")))

      expect(described_class.app_root).to eq("/rails/app")
    end

    it "falls back to Bundler.root when Rails.root is nil" do
      stub_const("Rails", double(root: nil))
      allow(Bundler).to receive(:root).and_return(Pathname.new("/bundled/app"))

      expect(described_class.app_root).to eq("/bundled/app")
    end

    it "falls back to Dir.pwd when Bundler has no Gemfile" do
      allow(Bundler).to receive(:root).and_raise(Bundler::GemfileNotFound)

      expect(described_class.app_root).to eq(Dir.pwd)
    end

    it "resolves to the Gemfile's directory in this test process" do
      expect(described_class.app_root).to eq(Bundler.root.to_s)
    end
  end
end

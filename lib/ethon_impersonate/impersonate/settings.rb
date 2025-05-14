# frozen_string_literal: true
require "rbconfig"
require "fileutils"
require "ffi/platform"

module EthonImpersonate
  module Impersonate
    module Settings
      LIB_VERSION = "1.0.0"
      LIB_EXT_PATH = File.expand_path("../../ext/", File.dirname(__dir__))

      LIB_DOWNLOAD_BASE_URL = "https://github.com/lexiforest/curl-impersonate/releases/download/v#{LIB_VERSION}/"

      LIB_OS_FULL_NAME_MAP = {
        "linux" => ["libcurl-impersonate.so.4.8.0", "libcurl-impersonate.4.8.0.so"],
        "darwin" => ["libcurl-impersonate.dylib.4", "libcurl-impersonate.4.dylib"],
        "windows" => ["libcurl.dll", "libcurl-impersonate.dll"],
      }.freeze

      LIB_PLATFORM_RELEASE_MAP = {
        # "aarch64-linux" => "libcurl-impersonate-v#{LIB_VERSION}.aarch64-linux-gnu.tar.gz",
        # "arm-linux" => "libcurl-impersonate-v#{LIB_VERSION}.arm-linux-gnueabihf.tar.gz",
        "aarch64-darwin" => "libcurl-impersonate-v#{LIB_VERSION}.arm64-macos.tar.gz",
        # "i386-linux" => "libcurl-impersonate-v#{LIB_VERSION}.i386-linux-gnu.tar.gz",
        # "i686-windows" => "libcurl-impersonate-v#{LIB_VERSION}.i686-win32.tar.gz",
        # "riscv64-linux" => "libcurl-impersonate-v#{LIB_VERSION}.riscv64-linux-gnu.tar.gz",
        "x86_64-linux" => "libcurl-impersonate-v#{LIB_VERSION}.x86_64-linux-gnu.tar.gz",
        # "x86_64-darwin" => "libcurl-impersonate-v#{LIB_VERSION}.x86_64-macos.tar.gz",
        # "x86_64-windows" => "libcurl-impersonate-v#{LIB_VERSION}.x86_64-win32.tar.gz",
      }.freeze

      GEM_PLATFORMS_MAP = {
        "aarch64-darwin" => ["arm64-darwin-24"],
        "x86_64-windows" => ["x64-mingw32"],
      }.freeze

      def self.ffi_libs
        libraries = []

        if ENV["CURL_IMPERSONATE_LIBRARY"]
          libraries << ENV["CURL_IMPERSONATE_LIBRARY"]
        end

        if lib_names.nil? || lib_names.empty?
          abort "Unsupported architecture/OS combination: #{arch_os}"
        end

        libraries += lib_names
        libraries += lib_names.map { |lib_name| File.join(LIB_EXT_PATH, lib_name) }

        libraries
      end

      def self.release_url(target_arch_os = nil)
        "#{LIB_DOWNLOAD_BASE_URL}#{lib_release_file(target_arch_os)}"
      end

      def self.lib_names(target_os = nil)
        target_os ||= FFI::Platform::OS
        names = LIB_OS_FULL_NAME_MAP[target_os]

        if names.nil?
          abort "Unsupported OS: #{target_os}"
        end

        names
      end

      def self.lib_release_file(target_arch_os = nil)
        target_arch_os ||= arch_os
        release = LIB_PLATFORM_RELEASE_MAP[target_arch_os]

        if release.nil?
          abort "Unsupported architecture/OS combination: #{target_arch_os}"
        end

        release
      end

      def self.arch_os
        "#{FFI::Platform::ARCH}-#{FFI::Platform::OS}"
      end
    end
  end
end

# frozen_string_literal: true
require "rbconfig"
require "fileutils"
require "ffi/platform"

module EthonImpersonate
  module Impersonate
    module Settings
      LIB_VERSION = "0.9.5"
      LIB_EXT_PATH = File.expand_path("../../ext/", File.dirname(__dir__))

      LIB_DOWNLOAD_BASE_URL = "https://github.com/lexiforest/curl-impersonate/releases/download/v#{LIB_VERSION}/"

      LIB_OS_FULL_NAME_MAP = {
        "linux" => "libcurl-impersonate-chrome.so.4.8.0",
        "darwin" => "libcurl-impersonate-chrome.dylib.4",
        "windows" => "libcurl.dll",
      }.freeze

      LIB_PLATFORM_RELEASE_MAP = {
        "aarch64-linux" => "libcurl-impersonate-v#{LIB_VERSION}.aarch64-linux-gnu.tar.gz",
        "arm-linux" => "libcurl-impersonate-v#{LIB_VERSION}.arm-linux-gnueabihf.tar.gz",
        "aarch64-darwin" => "libcurl-impersonate-v#{LIB_VERSION}.arm64-macos.tar.gz",
        "i386-linux" => "libcurl-impersonate-v#{LIB_VERSION}.i386-linux-gnu.tar.gz",
        "i686-windows" => "libcurl-impersonate-v#{LIB_VERSION}.i686-win32.tar.gz",
        "riscv64-linux" => "libcurl-impersonate-v#{LIB_VERSION}.riscv64-linux-gnu.tar.gz",
        "x86_64-linux" => "libcurl-impersonate-v#{LIB_VERSION}.x86_64-linux-gnu.tar.gz",
        "x86_64-darwin" => "libcurl-impersonate-v#{LIB_VERSION}.x86_64-macos.tar.gz",
        "x86_64-windows" => "libcurl-impersonate-v#{LIB_VERSION}.x86_64-win32.tar.gz",
      }.freeze

      def self.ffi_libs
        libraries = []

        if ENV["CURL_IMPERSONATE_LIBRARY"]
          libraries << ENV["CURL_IMPERSONATE_LIBRARY"]
        end

        if LIB_OS_FULL_NAME_MAP[FFI::Platform::OS].nil? && libraries.empty?
          abort "Unsupported architecture/OS combination: #{arch_os}"
        end

        libraries << LIB_OS_FULL_NAME_MAP[FFI::Platform::OS]
        libraries << File.join(LIB_EXT_PATH, LIB_OS_FULL_NAME_MAP[FFI::Platform::OS])

        if FFI::Platform::OS == "windows"
          libraries << File.join(LIB_EXT_PATH, "bin", LIB_OS_FULL_NAME_MAP[FFI::Platform::OS])
        end

        libraries
      end

      def self.release_url
        "#{LIB_DOWNLOAD_BASE_URL}#{lib_release_file}"
      end

      def self.lib_names
        names = LIB_PLATFORM_NAMES_MAP[arch_os]

        if names.nil?
          abort "Unsupported architecture/OS combination: #{arch_os}"
        end

        names
      end

      def self.lib_release_file
        release = LIB_PLATFORM_RELEASE_MAP[arch_os]

        if release.nil?
          abort "Unsupported architecture/OS combination: #{arch_os}"
        end

        release
      end

      def self.arch_os
        "#{FFI::Platform::ARCH}-#{FFI::Platform::OS}"
      end
    end
  end
end

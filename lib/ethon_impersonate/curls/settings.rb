# frozen_string_literal: true
module EthonImpersonate
  module Curl
    callback :callback, [:pointer, :size_t, :size_t, :pointer], :size_t
    callback :socket_callback, [:pointer, :int, :poll_action, :pointer, :pointer], :multi_code
    callback :timer_callback, [:pointer, :long, :pointer], :multi_code
    callback :debug_callback, [:pointer, :debug_info_type, :pointer, :size_t, :pointer], :int
    callback :progress_callback, [:pointer, :long_long, :long_long, :long_long, :long_long], :int
    ffi_lib_flags :now, :global

    ffi_lib [
      ENV['CURL_IMPERSONATE_PATH'],
      "libcurl-impersonate-chrome",
      "libcurl-impersonate-chrome.4.dylib",
      File.expand_path('../../../../ext/libcurl-impersonate-chrome', __FILE__),
      File.expand_path('../../../../ext/libcurl-impersonate-chrome.4.dylib', __FILE__),
    ]
  end
end

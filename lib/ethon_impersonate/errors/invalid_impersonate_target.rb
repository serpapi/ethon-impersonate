# frozen_string_literal: true
module EthonImpersonate
  module Errors

    class InvalidImpersonateTarget < ImpersonateFailed
      def initialize(target)
        message = "Invalid impersonation target: '#{target}'. " \
          "The loaded libcurl-impersonate (#{Curl.version.split(" ").first}) does not recognize it. " \
          "Available targets depend on the installed curl-impersonate version, " \
          "see https://github.com/lexiforest/curl-impersonate for supported targets."
        super(target, Curl::EasyCode[:bad_function_argument], message)
      end
    end
  end
end

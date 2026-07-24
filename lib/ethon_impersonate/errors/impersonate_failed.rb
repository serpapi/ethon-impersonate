# frozen_string_literal: true
module EthonImpersonate
  module Errors

    # Raises when curl_easy_impersonate failed.
    class ImpersonateFailed < EthonImpersonateError
      def initialize(target, code, message = nil)
        super(message || "Impersonation failed for target '#{target}': curl error #{code} (#{Curl.easy_strerror(code)}).")
      end
    end
  end
end

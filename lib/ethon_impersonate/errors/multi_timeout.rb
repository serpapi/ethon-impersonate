# frozen_string_literal: true
module EthonImpersonate
  module Errors

    # Raised when multi_timeout failed.
    class MultiTimeout < EthonImpersonateError
      def initialize(code)
        super("An error occured getting the timeout: #{code}")
        # "An error occured getting the timeout: #{code}: #{Curl.multi_strerror(code)}"
      end
    end
  end
end

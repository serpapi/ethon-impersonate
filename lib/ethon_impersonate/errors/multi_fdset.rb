# frozen_string_literal: true
module EthonImpersonate
  module Errors

    # Raises when multi_fdset failed.
    class MultiFdset < EthonImpersonateError
      def initialize(code)
        super("An error occured getting the fdset: #{code}")
      end
    end
  end
end

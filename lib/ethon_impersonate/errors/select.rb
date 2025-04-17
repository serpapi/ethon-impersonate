# frozen_string_literal: true
module EthonImpersonate
  module Errors

    # Raised when select failed.
    class Select < EthonImpersonateError
      def initialize(errno)
        super("An error occured on select: #{errno}")
      end
    end
  end
end


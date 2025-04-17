# frozen_string_literal: true
module EthonImpersonate
  module Errors

    # Raises when global_init failed.
    class GlobalInit < EthonImpersonateError
      def initialize
        super("An error occured initializing curl.")
      end
    end
  end
end


# frozen_string_literal: true
module EthonImpersonate
  module Errors

    # Raises when option is invalid.
    class InvalidOption < EthonImpersonateError
      def initialize(option)
        super("The option: #{option} is invalid.")
      end
    end
  end
end


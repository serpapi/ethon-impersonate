# frozen_string_literal: true
module EthonImpersonate
  module Errors

    # Raises when option is invalid.
    class InvalidValue < EthonImpersonateError
      def initialize(option, value)
        super("The value: #{value} is invalid for option: #{option}.")
      end
    end
  end
end


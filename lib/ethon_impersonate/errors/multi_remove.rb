# frozen_string_literal: true
module EthonImpersonate
  module Errors

    # Raises when multi_remove_handle failed.
    class MultiRemove < EthonImpersonateError
      def initialize(code, easy)
        super("An error occured removing the easy handle: #{easy} from the multi: #{code}")
      end
    end
  end
end

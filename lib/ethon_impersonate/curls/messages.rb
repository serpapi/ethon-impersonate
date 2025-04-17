# frozen_string_literal: true
module EthonImpersonate
  module Curls

    # This module contains available message codes.
    module Messages

      # Return message codes.
      #
      # @example Return message codes.
      #   EthonImpersonate::Curl.msg_codes
      #
      # @return [ Array ] The messages codes.
      def msg_codes
        [:none, :done, :last]
      end
    end
  end
end

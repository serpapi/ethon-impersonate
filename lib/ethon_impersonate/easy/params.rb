# frozen_string_literal: true
require 'ethon_impersonate/easy/util'
require 'ethon_impersonate/easy/queryable'

module EthonImpersonate
  class Easy

    # This class represents HTTP request parameters.
    #
    # @api private
    class Params
      include EthonImpersonate::Easy::Util
      include EthonImpersonate::Easy::Queryable

      # Create a new Params.
      #
      # @example Create a new Params.
      #   Params.new({})
      #
      # @param [ Hash ] params The params to use.
      #
      # @return [ Params ] A new Params.
      def initialize(easy, params)
        @easy = easy
        @params = params || {}
      end
    end
  end
end

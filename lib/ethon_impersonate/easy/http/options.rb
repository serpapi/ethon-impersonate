# frozen_string_literal: true
module EthonImpersonate
  class Easy
    module Http

      # This class knows everything about making OPTIONS requests.
      class Options
        include EthonImpersonate::Easy::Http::Actionable
        include EthonImpersonate::Easy::Http::Postable

        # Setup easy to make a OPTIONS request.
        #
        # @example Setup.
        #   options.setup(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def setup(easy)
          super
          easy.customrequest = "OPTIONS"
        end
      end
    end
  end
end

# frozen_string_literal: true
module EthonImpersonate
  class Easy
    module Http

      # This class knows everything about making GET requests.
      class Get
        include EthonImpersonate::Easy::Http::Actionable
        include EthonImpersonate::Easy::Http::Postable

        # Setup easy to make a GET request.
        #
        # @example Setup.
        #   get.set_params(easy)
        #
        # @param [ Easy ] easy The easy to setup.
        def setup(easy)
          super
          easy.customrequest = "GET" unless form.empty?
        end
      end
    end
  end
end

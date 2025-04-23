# frozen_string_literal: true
module EthonImpersonate
  class Easy
    # This module contains the logic around adding headers to libcurl.
    #
    # @api private
    module Header
      # Return headers, return empty hash if none.
      #
      # @example Return the headers.
      #   easy.headers
      #
      # @return [ Hash ] The headers.
      def headers
        @headers ||= {}
      end

      # Set the headers.
      #
      # @example Set the headers.
      #   easy.headers = {'User-Agent' => 'EthonImpersonate'}
      #
      # @param [ Hash ] headers The headers.
      def headers=(headers)
        headers ||= {}
        header_list = nil
        headers.each do |k, v|
          v_list = v.is_a?(Array) ? v : [v]

          v_list.each do |v_item|
            header_list = Curl.slist_append(header_list, compose_header(k,v_item))
          end
        end
        Curl.set_option(:httpheader, header_list, handle)

        @header_list = header_list && FFI::AutoPointer.new(header_list, Curl.method(:slist_free_all))
      end

      # Return header_list.
      #
      # @example Return header_list.
      #   easy.header_list
      #
      # @return [ FFI::Pointer ] The header list.
      def header_list
        @header_list
      end

      # Compose libcurl header string from key and value.
      # Also replaces null bytes, because libcurl will complain
      # otherwise.
      #
      # @example Compose header.
      #   easy.compose_header('User-Agent', 'EthonImpersonate')
      #
      # @param [ String ] key The header name.
      # @param [ String ] value The header value.
      #
      # @return [ String ] The composed header.
      def compose_header(key, value)
        Util.escape_zero_byte("#{key}: #{value}")
      end
    end
  end
end

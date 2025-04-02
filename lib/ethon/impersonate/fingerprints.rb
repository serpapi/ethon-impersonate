module Ethon
  module Impersonate
    module Fingerprints
      DEFAULT_EXTRAS = {
        tls_min_version: :tlsv1_2,
        tls_grease: false,
        tls_permute_extensions: false,
        tls_cert_compression: "brotli",
        tls_signature_algorithms: nil,
        http2_stream_weight: 256,
        http2_stream_exclusive: 1,
      }.freeze
    end
  end
end

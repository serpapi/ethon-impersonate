# frozen_string_literal: true
require 'logger'
require 'ffi'
require 'thread'
begin
  require 'mime/types/columnar'
rescue LoadError
  begin
    require 'mime/types'
  rescue LoadError
  end
end
require 'tempfile'

require 'ethon_impersonate/libc'
require 'ethon_impersonate/curl'
require 'ethon_impersonate/easy'
require 'ethon_impersonate/errors'
require 'ethon_impersonate/loggable'
require 'ethon_impersonate/multi'
require 'ethon_impersonate/impersonate'
require 'ethon_impersonate/version'

# EthonImpersonate is a very simple curl-impersonate wrapper.
# It provides direct access to libcurl functionality
# as well as some helpers for doing http requests.
module EthonImpersonate
end

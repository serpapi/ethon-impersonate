# encoding: utf-8
# frozen_string_literal: true
lib = File.expand_path("../lib/", __FILE__)
$:.unshift lib unless $:.include?(lib)

require "ethon_impersonate/version"

Gem::Specification.new do |s|
  s.name         = "ethon-impersonate"
  s.version      = EthonImpersonate::VERSION
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["David Sojevic", "Hans Hasselberg"]
  s.email        = ["david@sojevic.com"]
  s.homepage     = "https://github.com/dsojevic/ethon-impersonate"
  s.summary      = "curl-impersonate wrapper."
  s.description  = "curl-impersonate wrapper."

  s.required_rubygems_version = ">= 1.3.6"
  s.license = "MIT"

  s.add_dependency("ffi", [">= 1.15.0"])

  s.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |file|
      file.start_with?(*%w[. Gemfile Guardfile Rakefile profile spec])
    end
  end
  s.require_path = "lib"
end

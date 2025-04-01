# frozen_string_literal: true
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'bundler'
Bundler.setup
require "ethon"
require "rspec"

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.order = :rand

  config.before(:suite) do
    LocalhostServer.new(TESTSERVER.new, 3001)
  end
end

# frozen_string_literal: true
source "https://rubygems.org"
gemspec

gem "rake"

group :development, :test do
  gem "rspec", "~> 3.4"

  gem "sinatra", "~> 1.3"

  if Gem.ruby_version >= Gem::Version.new("3.0.0")
    gem "webrick"
    gem "logger"
    gem "ostruct"
  end

  gem "json"
  gem "mime-types", "~> 1.18"
  gem "mustermann"
end

# frozen_string_literal: true
require "rails/railtie"

module EthonImpersonate
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path("tasks/update_lib.rake", __dir__)
    end
  end
end

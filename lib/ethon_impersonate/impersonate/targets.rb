# frozen_string_literal: true
module EthonImpersonate
  module Impersonate
    module Targets
      CHROME_MOBILE_TARGETS = [
        "chrome99_android",
        "chrome131_android",
      ].freeze

      CHROME_DESKTOP_TARGETS = [
        "chrome99",
        "chrome100",
        "chrome101",
        "chrome104",
        "chrome107",
        "chrome110",
        "chrome116",
        "chrome119",
        "chrome120",
        "chrome123",
        "chrome124",
        "chrome131",
        "chrome133a",
      ].freeze

      CHROME_TARGETS = [
        *CHROME_MOBILE_TARGETS,
        *CHROME_DESKTOP_TARGETS,
      ].freeze

      EDGE_TARGETS = [
        "edge99",
        "edge101",
      ].freeze

      FIREFOX_TARGETS = [
        "firefox133",
        "firefox135",
      ].freeze

      SAFARI_MOBILE_TARGETS = [
        "safari17_2_ios",
        "safari18_0_ios",
      ].freeze

      SAFARI_DESKTOP_TARGETS = [
        "safari15_3",
        "safari15_5",
        "safari17_0",
        "safari18_0",
      ].freeze

      SAFARI_TARGETS = [
        *SAFARI_MOBILE_TARGETS,
        *SAFARI_DESKTOP_TARGETS,
      ].freeze

      ALL_TARGETS = [
        *EDGE_TARGETS,
        *CHROME_TARGETS,
        *SAFARI_TARGETS,
        *FIREFOX_TARGETS,
      ].freeze

      ALIASES = {
        "chrome" => CHROME_DESKTOP_TARGETS.last,
        "chrome_android" => CHROME_MOBILE_TARGETS.last,
        "edge" => EDGE_TARGETS.last,
        "firefox" => FIREFOX_TARGETS.last,
        "safari" => SAFARI_DESKTOP_TARGETS.last,
        "safari_ios" => SAFARI_MOBILE_TARGETS.last,
      }.freeze

      BROWSERS = [
        *CHROME_TARGETS,
        *EDGE_TARGETS,
        *FIREFOX_TARGETS,
        *SAFARI_TARGETS,
        *ALIASES.keys,
      ].freeze

      class << self
        def valid_browser?(browser)
          BROWSERS.include?(browser.to_s)
        end
      end
    end
  end
end

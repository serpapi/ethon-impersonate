# frozen_string_literal: true
require 'ethon_impersonate'
require 'ethon_impersonate/easy'

require_relative 'perf_spec_helper'
require 'rspec/autorun'

describe "low-level interactions with libcurl" do
  describe EthonImpersonate::Multi do
    memory_leak_test("init") do
      EthonImpersonate::Multi.new
    end

    memory_leak_test("handle") do
      EthonImpersonate::Multi.new.handle
    end
  end

  describe EthonImpersonate::Easy do
    memory_leak_test("init") do
      EthonImpersonate::Easy.new
    end

    memory_leak_test("handle") do
      EthonImpersonate::Easy.new.handle
    end

    memory_leak_test("headers") do
      EthonImpersonate::Easy.new.headers = { "a" => 1, "b" => 2, "c" => 3, "d" => 4}
    end

    memory_leak_test("escape") do
      EthonImpersonate::Easy.new.escape("the_sky&is_blue")
    end
  end


  describe EthonImpersonate::Easy::Form do
    memory_leak_test("init") do
      EthonImpersonate::Easy::Form.new(nil, {})
    end

    memory_leak_test("first") do
      EthonImpersonate::Easy::Form.new(nil, {}).first
    end

    memory_leak_test("last") do
      EthonImpersonate::Easy::Form.new(nil, {}).last
    end

    memory_leak_test("materialized with some params") do
      form = EthonImpersonate::Easy::Form.new(nil, { "a" => "1" })
      form.materialize
    end

    memory_leak_test("materialized with a file") do
      File.open(__FILE__, "r") do |file|
        form = EthonImpersonate::Easy::Form.new(nil, { "a" => file })
        form.materialize
      end
    end
  end
end

describe "higher level operations" do
  memory_leak_test("a simple request") do
    EthonImpersonate::Easy.new(url: "http://localhost:3001/",
                    forbid_reuse: true).perform
  end

  memory_leak_test("a request with headers") do
    EthonImpersonate::Easy.new(url: "http://localhost:3001/",
                    headers: { "Content-Type" => "application/json",
                                  "Something" => "1",
                                  "Else" => "qwerty",
                                  "Long-String" => "aassddffgghhiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz"},
                    forbid_reuse: true).perform
  end

  memory_leak_test("a request with headers and params") do
    easy = EthonImpersonate::Easy.new(url: "http://localhost:3001/",
                    headers: { "Content-Type" => "application/json",
                                  "Something" => "1",
                                  "Else" => "qwerty",
                                  "Long-String" => "aassddffgghhiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz"},
                    forbid_reuse: true)
    easy.http_request("http://localhost:3001/",
                      :get,
                      params: { "param1" => "value1",
                                   "param2" => "value2",
                                   "param3" => "value3",
                                   "param4" => "value4"})
  end

  memory_leak_test("a request with headers, params, and body") do
    easy = EthonImpersonate::Easy.new(url: "http://localhost:3001/",
                    headers: { "Content-Type" => "application/json",
                                  "Something" => "1",
                                  "Else" => "qwerty",
                                  "Long-String" => "aassddffgghhiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz"},
                    forbid_reuse: true)
    easy.http_request("http://localhost:3001/",
                      :get,
                      params: { "param1" => "value1",
                                   "param2" => "value2",
                                   "param3" => "value3",
                                   "param4" => "value4"},
                      body: {
                        "body1" => "value1",
                        "body2" => "value2",
                        "body3" => "value3"
                      })
  end
end

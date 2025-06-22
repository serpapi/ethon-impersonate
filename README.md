

#  Ethon Impersonate ![Chrome](https://raw.githubusercontent.com/alrra/browser-logos/main/src/chrome/chrome_24x24.png "Chrome") ![Edge](https://raw.githubusercontent.com/alrra/browser-logos/main/src/edge/edge_24x24.png "Edge") ![Safari](https://raw.githubusercontent.com/alrra/browser-logos/main/src/safari/safari_24x24.png "Safari") ![Firefox](https://raw.githubusercontent.com/alrra/browser-logos/main/src/firefox/firefox_24x24.png "Firefox") ![Tor](https://raw.githubusercontent.com/alrra/browser-logos/main/src/tor/tor_24x24.png "Tor")

[![Gem Version](https://badge.fury.io/rb/ethon-impersonate.svg)](https://badge.fury.io/rb/ethon-impersonate)
[![Build Status](https://github.com/serpapi/ethon-impersonate/workflows/Ruby/badge.svg)](https://github.com/serpapi/ethon-impersonate/actions/workflows/ruby.yml)

**Ethon Impersonate** is a fork of [Ethon](https://github.com/typhoeus/ethon) that wraps [libcurl-impersonate](https://github.com/lexiforest/curl-impersonate).

In Greek mythology, Ethon, the son of Typhoeus and Echidna, is a gigantic eagle. So much for the history.

This allows you to make HTTP requests that appear to come from real browsers, helping to bypass bot detection and fingerprinting.

## Installation

With bundler:
```bash
gem "ethon-impersonate"
```

With rubygems:
```bash
gem install ethon-impersonate
```

## Usage

Making the first request is simple:

```ruby
easy = EthonImpersonate::Easy.new(url: "www.example.com")
easy.perform
#=> :ok
```

You have access to various options, such as following redirects:

```ruby
easy = EthonImpersonate::Easy.new(url: "www.example.com", followlocation: true)
easy.perform
#=> :ok
```

Once you're done you can inspect the response code and body:

```ruby
easy = EthonImpersonate::Easy.new(url: "www.example.com", followlocation: true)
easy.perform
easy.response_code
#=> 200
easy.response_body
#=> "<!doctype html><html ..."
```

## Browser Impersonation

The main feature of this gem is the ability to impersonate real browsers. Use the `impersonate` method to configure the request to look like it's coming from a specific browser:

```ruby
easy = EthonImpersonate::Easy.new(url: "www.example.com")
easy.impersonate("chrome136")  # Impersonate Chrome 136
easy.perform
easy.response_code
#=> 200
```

### Available Browser Targets

The gem supports all browser targets available in curl-impersonate. Some popular targets include:

- **Chrome**: `chrome136`, `chrome131_android`
- **Firefox**: `firefox135`
- **Safari**: `safari184`, `safari184_ios`
- **Edge**: `edge101`
- **Tor**: `tor145`

For a complete list of available targets, see the [curl-impersonate bin directory](https://github.com/lexiforest/curl-impersonate/tree/main/bin).

### Example with Browser Impersonation

```ruby
# Impersonate Chrome 136
easy = EthonImpersonate::Easy.new(url: "https://tls.browserleaks.com/json")
easy.impersonate("chrome136")
easy.perform
#=> :ok

# Impersonate Firefox 135
easy = EthonImpersonate::Easy.new(url: "https://tls.browserleaks.com/json")
easy.impersonate("firefox135")
easy.perform
#=> :ok

# Impersonate Safari 184
easy = EthonImpersonate::Easy.new(url: "https://tls.browserleaks.com/json")
easy.impersonate("safari184")
easy.perform
#=> :ok
```

## Http

In order to make life easier, there are some helpers for making HTTP requests:

```ruby
easy = EthonImpersonate::Easy.new
easy.http_request("www.example.com", :get, { params: {a: 1} })
easy.perform
#=> :ok
```

```ruby
easy = EthonImpersonate::Easy.new
easy.http_request("www.example.com", :post, { params: { a: 1 }, body: { b: 2 } })
easy.perform
#=> :ok
```

This is really handy when making requests since you don't have to care about setting
everything up correctly.

## Http2
Standard http2 servers require the client to connect once and create a session (multi) and then add simple requests to the multi handler.
The `perform` method then takes all the requests in the multi handler and sends them to the server.

See the following example
```ruby
multi = EthonImpersonate::Multi.new
easy = EthonImpersonate::Easy.new

easy.http_request("www.example.com/get", :get, { http_version: :httpv2_0 })

# Sending a request with http version 2 will send an Upgrade header to the server, which many older servers will not support
# See below for more info: https://everything.curl.dev/http/http2
# If this is a problem, send the below:
easy.http_request("www.example.com/get", :get, { http_version: :httpv2_prior_knowledge })

# To set the server to use http2 with https and http1 with http, send the following:
easy.http_request("www.example.com/get", :get, { http_version: :httpv2_tls })

multi.add(easy)
multi.perform
```

## Sponsors

Ethon Impersonate is maintained by **SerpApi**.

Thanks to all <a href="https://github.com/serpapi/ethon-impersonate/graphs/contributors">contributors</a> of this project past and present.

------

<a href="https://serpapi.com/" target="_blank"><img src="https://raw.githubusercontent.com/serpapi/ethon-impersonate/master/assets/serpapi.png" alt="SerpAPI" height="67" width="63"></a>

Scrape Google and other search engines from [SerpApi](https://serpapi.com/)'s fast, easy, and complete API. 0.66s average response time (≤ 0.5s for Ludicrous Speed Max accounts), 99.95% SLAs, pay for successful responses only.

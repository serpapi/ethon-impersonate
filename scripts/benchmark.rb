require "benchmark"
require "active_support/core_ext/benchmark"
require "pry"

# Load `ethon-impersonate` instead of `ethon`
$:.unshift File.expand_path("../../lib", __FILE__)
require "ethon"
require "curb"
require "typhoeus"
require "http"

require "connection_pool"

# Based on: https://github.com/typhoeus/typhoeus/blob/master/lib/typhoeus/pool.rb
module TyphoeusGlobalPool
  @mutex = Mutex.new
  @pid = Process.pid

  def self.release(handle)
    @mutex.synchronize { handles << handle }
  end

  def self.get(ctx)
    @mutex.synchronize do
      if @pid == Process.pid
        handles.pop
      else
        # Process has forked. Clear all handles to avoid sockets being
        # shared between processes.
        @pid = Process.pid
        handles.clear
        nil
      end
    end || ctx.send("create_handle_#{ctx.adapter}")
  end

  def self.clear
    @mutex.synchronize { handles.clear }
  end

  def self.with(ctx, &block)
    handle = get(ctx)
    yield handle
  ensure
    release(handle) if handle
  end

  def self.handles
    @handles ||= []
  end
end

class Setup
  attr_reader :adapter, :persistent, :pool, :libcurl_tweaks, :impersonate, :pool_instance

  POOL_SIZE = 10

  IMPERSONATE_TARGET = "chrome131"

  URL = "https://serpapi.com/robots.txt"

  def initialize(adapter:, persistent: false, pool: nil, libcurl_tweaks: false, impersonate: false)
    @adapter = adapter
    @persistent = persistent
    @pool = pool
    @libcurl_tweaks = libcurl_tweaks
    @impersonate = impersonate
  end

  def pool_instance
    @pool_instance ||= begin
      if pool.nil? || adapter == :typhoeus
        :not_used
      elsif pool == :connection_pool
        ConnectionPool.new(size: POOL_SIZE, timeout: 5) do
          send "create_handle_#{adapter}"
        end
      elsif pool == :typhoeus_global_pool
        TyphoeusGlobalPool.clear
        TyphoeusGlobalPool
      else
        raise "unknown pool: #{pool}"
      end
    end
  end

  def create_handle_httprb
    handle = HTTP::Client.new

    if persistent
      handle = handle.persistent(URL, timeout: 30)
    end

    handle
  end

  # Persistent connections in `libcurl` are enabled by default,
  # connection are established and kept on the first request.
  def create_handle_ethon
    handle = Ethon::Easy.new
    config_handle_ethon(handle)
    handle
  end

  def create_handle_curb
    handle = Curl::Easy.new
    config_handle_curb(handle)
    handle
  end

  def config_handle_ethon(handle)
    if libcurl_tweaks
      handle.nosignal = true
    end

    unless persistent
      handle.forbid_reuse = true
    end

    if impersonate
      handle.impersonate(IMPERSONATE_TARGET)
    end
  end

  def config_handle_curb(handle)
    if libcurl_tweaks
      handle.nosignal = true
    end

    unless persistent
      handle.setopt(Curl::CURLOPT_FORBID_REUSE, 1)
    end
  end

  def request
    if pool_instance == :not_used
      send "make_request_#{adapter}"
    else
      send "make_request_#{pool}"
    end
  end

  def make_request_connection_pool
    pool_instance.with do |handle|
      send "make_request_#{adapter}", handle
    end
  end

  def make_request_typhoeus_global_pool
    pool_instance.with(self) do |handle|
      send "make_request_#{adapter}", handle
    end
  end

  def make_request_httprb(handle = nil)
    response = nil

    total_time = measure_total_time do
      handle ||= create_handle_httprb
      response = handle.get(URL)
    end

    _body = response.to_s # body should be read
    status = response.code

    [status, total_time]
  end

  def make_request_ethon(handle = nil)
    total_time = measure_total_time do
      handle ||= create_handle_ethon
      handle.http_request(URL, :get)
      handle.perform
    end

    status = handle.response_code
    _body = handle.response_body # body should be read

    unless persistent
      handle.cookielist = "all"
      handle.reset

      # config should re-applied after reset
      config_handle_ethon(handle)
    end

    [status, total_time]
  end

  def make_request_curb(handle = nil)
    total_time = measure_total_time do
      handle ||= create_handle_curb
      handle.url = URL
      handle.http(:GET)
    end

    status = handle.code
    _body = handle.body # body should be read

    unless persistent
      handle.setopt(Curl::CURLOPT_COOKIELIST, "all")
      handle.reset

      # config should re-applied after reset
      config_handle_curb(handle)
    end

    [status, total_time]
  end

  def make_request_typhoeus
    response = nil

    total_time = measure_total_time do
      response = Typhoeus::Request.new(URL, method: :get).run
    end

    status = response.response_code
    _body = response.response_body # body should be read

    [status, total_time]
  end

  # `.total_time` can be used with libcurl handles instead, but it doesn't include handle creation time for non-pool runs
  # httprb does not have `.total_time` alternative at all
  def measure_total_time
    Benchmark.realtime { yield }.round(3)
  end
end

REQUESTS = 100

setups = {
  "httprb" => {
    adapter: :httprb,
    persistent: false
  },
  "httprb + persistent + connection pool" => {
    adapter: :httprb,
    persistent: true,
    pool: :connection_pool
  },
  "httprb + persistent + typhoeus global pool" => {
    adapter: :httprb,
    persistent: true,
    pool: :typhoeus_global_pool
  },
  "ethon" => {
    adapter: :ethon,
    persistent: false
  },
  "ethon + persistent + connection pool" => {
    adapter: :ethon,
    persistent: true,
    pool: :connection_pool
  },
  "ethon + persistent + typhoeus global pool" => {
    adapter: :ethon,
    persistent: true,
    pool: :typhoeus_global_pool
  },
  "ethon + persistent + impersonate + connection pool" => {
    adapter: :ethon,
    persistent: true,
    pool: :connection_pool,
    impersonate: true
  },
  "ethon + persistent + impersonate + connection pool + libcurl tweaks" => {
    adapter: :ethon,
    persistent: true,
    pool: :connection_pool,
    libcurl_tweaks: true,
    impersonate: true
  },
  "curb" => {
    adapter: :curb,
    persistent: false
  },
  "curb + persistent + connection pool" => {
    adapter: :curb,
    persistent: true,
    pool: :connection_pool
  },
  "curb + persistent + typhoeus global pool" => {
    adapter: :curb,
    persistent: true,
    pool: :typhoeus_global_pool
  },
  "curb + persistent + connection pool + libcurl tweaks" => {
    adapter: :ethon,
    persistent: true,
    pool: :connection_pool,
    libcurl_tweaks: true
  },
  "typhoeus (persistent, built-in pool)" => {
    adapter: :typhoeus
  },
}

title_offset = setups.keys.map(&:size).max

stats_per_setup = {}

Benchmark.bm(title_offset) do |x|
  setups.each do |title, config|
    setup = Setup.new(config)
    responses = nil

    x.report(title) do
      responses = REQUESTS.times.map { setup.request }
    end

    statuses = responses.map(&:first)
    statuses_stats = statuses.tally

    total_times = responses.map(&:last)

    unless total_times.empty?
      total_time_avg = (total_times.sum.to_f / total_times.size).round(3)
      total_time_max = total_times.max
    end

    stats_per_setup[title] = {
      statuses: statuses_stats,
      total_time: {
        avg: total_time_avg,
        max: total_time_max
      }
    }
  end
end

puts "\nStatuses:\n"

stats_per_setup.each do |title, stats|
  puts "#{title.ljust(title_offset)} | #{stats[:statuses]}"
end

puts "\nRequest times:\n"

stats_per_setup.each do |title, stats|
  puts "#{title.ljust(title_offset)} | avg: #{stats[:total_time][:avg]}, max: #{stats[:total_time][:max]}"
end

# [100 requests]
#                                                                           user     system      total        real
# httprb                                                                0.821744   0.197586   1.019330 ( 20.611882)
# httprb + persistent + connection pool                                 0.209725   0.022617   0.232342 (  4.618736)
# httprb + persistent + typhoeus global pool                            0.201539   0.022894   0.224433 (  5.402828)
# ethon                                                                 1.538791   0.329745   1.868536 ( 71.929067)
# ethon + persistent + connection pool                                  0.071483   0.033594   0.105077 (  4.843713)
# ethon + persistent + typhoeus global pool                             0.071650   0.034861   0.106511 (  4.869447)
# ethon + persistent + impersonate + connection pool                    0.078345   0.027579   0.105924 (  5.265247)
# ethon + persistent + impersonate + connection pool + libcurl tweaks   0.178658   0.045567   0.224225 (  4.811430)
# curb                                                                  1.973892   0.438524   2.412416 ( 70.635202)
# curb + persistent + connection pool                                   0.082820   0.032683   0.115503 (  5.752412)
# curb + persistent + typhoeus global pool                              0.057185   0.029840   0.087025 (  5.615714)
# curb + persistent + connection pool + libcurl tweaks                  0.070365   0.032776   0.103141 (  4.376364)
# typhoeus (persistent, built-in pool)                                  0.275557   0.054279   0.329836 (  5.142657)

# Statuses:
# httprb                                                              | {200=>100}
# httprb + persistent + connection pool                               | {200=>100}
# httprb + persistent + typhoeus global pool                          | {200=>100}
# ethon                                                               | {200=>100}
# ethon + persistent + connection pool                                | {200=>100}
# ethon + persistent + typhoeus global pool                           | {200=>100}
# ethon + persistent + impersonate + connection pool                  | {200=>100}
# ethon + persistent + impersonate + connection pool + libcurl tweaks | {200=>100}
# curb                                                                | {200=>100}
# curb + persistent + connection pool                                 | {200=>100}
# curb + persistent + typhoeus global pool                            | {200=>100}
# curb + persistent + connection pool + libcurl tweaks                | {200=>100}
# typhoeus (persistent, built-in pool)                                | {200=>100}

# Request times:
# httprb                                                              | avg: 0.206, max: 0.252
# httprb + persistent + connection pool                               | avg: 0.046, max: 0.199
# httprb + persistent + typhoeus global pool                          | avg: 0.054, max: 0.236
# ethon                                                               | avg: 0.719, max: 9.217
# ethon + persistent + connection pool                                | avg: 0.048, max: 0.14
# ethon + persistent + typhoeus global pool                           | avg: 0.049, max: 0.127
# ethon + persistent + impersonate + connection pool                  | avg: 0.053, max: 0.14
# ethon + persistent + impersonate + connection pool + libcurl tweaks | avg: 0.048, max: 0.124
# curb                                                                | avg: 0.706, max: 9.223
# curb + persistent + connection pool                                 | avg: 0.057, max: 0.32
# curb + persistent + typhoeus global pool                            | avg: 0.056, max: 0.308
# curb + persistent + connection pool + libcurl tweaks                | avg: 0.044, max: 0.124
# typhoeus (persistent, built-in pool)                                | avg: 0.051, max: 0.135


# [500 requests]
#                                                                           user     system      total        real
# httprb                                                                4.178775   0.942253   5.121028 (111.538155)
# httprb + persistent + connection pool                                 1.035668   0.108627   1.144295 ( 24.986391)
# httprb + persistent + typhoeus global pool                            1.001590   0.100725   1.102315 ( 27.323462)
# ethon + persistent + connection pool                                  0.358773   0.149643   0.508416 ( 25.192268)
# ethon + persistent + typhoeus global pool                             0.313371   0.143549   0.456920 ( 27.550469)
# ethon + persistent + impersonate + connection pool                    0.389527   0.110366   0.499893 ( 24.388239)
# ethon + persistent + impersonate + connection pool + libcurl tweaks   0.385782   0.109955   0.495737 ( 25.875923)
# curb + persistent + connection pool                                   0.293990   0.127672   0.421662 ( 27.215274)
# curb + persistent + typhoeus global pool                              0.273668   0.136113   0.409781 ( 32.075233)
# curb + persistent + connection pool + libcurl tweaks                  0.333425   0.143318   0.476743 ( 25.450606)
# typhoeus (persistent, built-in pool)                                  0.788164   0.154691   0.942855 ( 23.797588)

# Statuses:
# httprb                                                              | {200=>500}
# httprb + persistent + connection pool                               | {200=>500}
# httprb + persistent + typhoeus global pool                          | {200=>500}
# ethon + persistent + connection pool                                | {200=>500}
# ethon + persistent + typhoeus global pool                           | {200=>500}
# ethon + persistent + impersonate + connection pool                  | {200=>500}
# ethon + persistent + impersonate + connection pool + libcurl tweaks | {200=>500}
# curb + persistent + connection pool                                 | {200=>500}
# curb + persistent + typhoeus global pool                            | {200=>500}
# curb + persistent + connection pool + libcurl tweaks                | {200=>500}
# typhoeus (persistent, built-in pool)                                | {200=>500}

# Request times:
# httprb                                                              | avg: 0.223, max: 0.512
# httprb + persistent + connection pool                               | avg: 0.05, max: 0.454
# httprb + persistent + typhoeus global pool                          | avg: 0.055, max: 0.199
# ethon + persistent + connection pool                                | avg: 0.05, max: 0.289
# ethon + persistent + typhoeus global pool                           | avg: 0.055, max: 0.434
# ethon + persistent + impersonate + connection pool                  | avg: 0.049, max: 0.428
# ethon + persistent + impersonate + connection pool + libcurl tweaks | avg: 0.052, max: 0.264
# curb + persistent + connection pool                                 | avg: 0.054, max: 0.319
# curb + persistent + typhoeus global pool                            | avg: 0.064, max: 0.326
# curb + persistent + connection pool + libcurl tweaks                | avg: 0.051, max: 0.198
# typhoeus (persistent, built-in pool)                                | avg: 0.048, max: 0.344

##
# [macOS]
#
# To run in processes:
# OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES ruby stress_test.rb
#
# Set higher `ulimit` to run in general:
# ulimit -n
# => 256  -- this is to low, causes `couldnt_resolve_host` errors
#
# ulimit -n 4096  -- should be fine
#

ADAPTER = :ethon # :httprb, :ethon, :curb, :typhoeus

IMPERSONATE = true
IMPERSONATE_TARGET = "chrome131"

# `libcurl` gems should be initiated BEFORE `parallel`,
# otherwise it may lead to random thread errors.
if ADAPTER == :ethon
  if IMPERSONATE
    $:.unshift File.expand_path("../../lib", __FILE__)
  end

  require "ethon_impersonate"
end

require "curb"     if ADAPTER == :curb
require "typhoeus" if ADAPTER == :typhoeus
require "http"     if ADAPTER == :httprb

require "parallel"
require "connection_pool"

REQUESTS = 1000
PROCESSES = 4
THREADS = 10

# These params are not applicable to `typhoeus` as it uses own pool under the hood
# and keeps connections by default.
POOL = :connection_pool # nil, :connection_pool, :typhoeus_global_pool
PERSISTENT = true
LIBCURL_TWEAKS = true # Set additional params for libcurl handles to improve thread-safety

URL = "https://serpapi.com/robots.txt"

# for connection timeout
# URL = "https://www.google.com:81"

VERBOSE = true

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
    end || ctx.send("create_handle_#{ADAPTER}")
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

def pool
  @pool ||= begin
    if POOL.nil? || ADAPTER == :typhoeus
      :not_used
    elsif POOL == :connection_pool
      ConnectionPool.new(size: THREADS, timeout: 5) do
        # Persistent connections in `libcurl` are enabled by default.
        # Connection will be established and kept on the first request.
        send "create_handle_#{ADAPTER}"
      end
    elsif POOL == :typhoeus_global_pool
      TyphoeusGlobalPool
    else
      raise "unknown pool: #{POOL}"
    end
  end
end

def create_handle_httprb
  handle = HTTP::Client.new

  if PERSISTENT
    handle = handle.persistent(URL, timeout: 30)
  end

  handle
end

def create_handle_ethon
  handle = EthonImpersonate::Easy.new
  config_handle_ethon(handle)
  handle
end

def create_handle_curb
  handle = Curl::Easy.new
  config_handle_curb(handle)
  handle
end

def config_handle_ethon(handle)
  if LIBCURL_TWEAKS
    handle.nosignal = true
  end

  unless PERSISTENT
    handle.forbid_reuse = true
  end

  if IMPERSONATE
    handle.impersonate(IMPERSONATE_TARGET)
  end
end

def config_handle_curb(handle)
  if LIBCURL_TWEAKS
    handle.nosignal = true
  end

  unless PERSISTENT
    handle.setopt(Curl::CURLOPT_FORBID_REUSE, 1)
  end
end

def request(process_id, request_id)
  status =
    if pool == :not_used
      send "make_request_#{ADAPTER}"
    else
      send "make_request_#{POOL}"
    end

  if VERBOSE
    puts "[#{process_id}][#{request_id}]: #{status}"
  end

  status
end

def make_request_connection_pool
  pool.with do |handle|
    send "make_request_#{ADAPTER}", handle
  end
end

def make_request_typhoeus_global_pool
  pool.with(self) do |handle|
    send "make_request_#{ADAPTER}", handle
  end
end

def make_request_httprb(handle = nil)
  handle ||= create_handle_httprb
  response = handle.get(URL)

  _body = response.to_s # body should be read
  response.code
rescue => error
  error.to_s
end

def make_request_ethon(handle = nil)
  handle ||= create_handle_ethon
  handle.http_request(URL, :get)
  handle.perform

  status = handle.return_code
  _body = handle.response_body # body should be read

  unless PERSISTENT
    handle.cookielist = "all"
    handle.reset

    # config should re-applied after reset
    config_handle_ethon(handle)
  end

  status
end

def make_request_curb(handle = nil)
  handle ||= create_handle_curb
  handle.url = URL
  handle.http(:GET)

  status = handle.code # no way to get return code string similar to `ethon` and `typhoeus`
  _body = handle.body # body should be read

  unless PERSISTENT
    handle.setopt(Curl::CURLOPT_COOKIELIST, "all")
    handle.reset

    # config should re-applied after reset
    config_handle_curb(handle)
  end

  status
rescue => error
  error.to_s
end

def make_request_typhoeus
  response = Typhoeus::Request.new(URL, method: :get).run

  status = response.return_code
  _body = response.response_body # body should be read

  status
end

def via_processes
  if PROCESSES > 1
    Parallel.map((1..PROCESSES).to_a, in_processes: PROCESSES) do |process_id|
      via_threads(process_id)
    end.flatten
  else
    via_threads(1)
  end
end

def via_threads(process_id)
  if THREADS > 1
    Parallel.map((1..REQUESTS).to_a, in_threads: THREADS) do |request_id|
      request(process_id, request_id)
    end
  else
    REQUESTS.times.map do |request_id|
      request(process_id, request_id)
    end
  end
end

if __FILE__ == $0
  statuses = via_processes

  title =
    if ADAPTER == :ethon && IMPERSONATE
      "ethon-impersonate"
    else
      "#{ADAPTER}"
    end

  unless ADAPTER == :typhoeus
    title << " + persistent" if PERSISTENT
    title << " + impersonate" if IMPERSONATE && ADAPTER == :ethon
    title << " + libcurl tweaks" if LIBCURL_TWEAKS && ADAPTER != :httprb

    case POOL
    when :connection_pool
      title << " + connection pool"
    when :typhoeus_global_pool
      title << " + typhoeus global pool"
    end
  end

  puts "#{title} | #{statuses.tally}"
end

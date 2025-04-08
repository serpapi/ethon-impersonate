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

ADAPTER = :ethon # :ethon, :curb, :typhoeus

IMPERSONATE = true
IMPERSONATE_TARGET = "chrome131"

# `libcurl` gems should be initiated BEFORE `parallel`,
# otherwise it may lead to random thread errors.
if ADAPTER == :ethon
  if IMPERSONATE
    $:.unshift File.expand_path("../../lib", __FILE__)
  end

  require "ethon"
end

require "curb"     if ADAPTER == :curb
require "typhoeus" if ADAPTER == :typhoeus

require "parallel"
require "connection_pool"

REQUESTS = 1000
PROCESSES = 4
THREADS = 10

# These params are not applicable to `typhoeus` as it uses own pool under the hood.
# It also does not keep connections by default (unless used via curl multi interface)
POOL = :connection_pool # nil, :connection_pool, :typhoeus_global_pool
TWEAK_HANDLES = true # Set additional handle params to improve thread-safety
RESET_HANDLES = false # Fully reset handle after each request, disables persistent connections

URL = "https://serpapi.com/robots.txt"

VERBOSE = true

# Inspired by: https://github.com/typhoeus/typhoeus/blob/master/lib/typhoeus/pool.rb
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
    end || ctx.send("create_#{ADAPTER}_handle")
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
        send "create_#{ADAPTER}_handle"
      end
    elsif POOL == :typhoeus_global_pool
      TyphoeusGlobalPool
    else
      raise "unknown pool: #{POOL}"
    end
  end
end

def create_ethon_handle
  options = {}
  options.merge!(nosignal: true) if TWEAK_HANDLES
  options.merge!(forbid_reuse: true) if RESET_HANDLES

  handle = Ethon::Easy.new(options)

  if IMPERSONATE
    handle.impersonate(IMPERSONATE_TARGET)
  end

  handle
end

def create_curb_handle
  handle = Curl::Easy.new

  if TWEAK_HANDLES
    handle.nosignal = true
  end

  if RESET_HANDLES
    handle.setopt(Curl::CURLOPT_FORBID_REUSE, 1)
  end

  handle
end

def request(process_id, request_id)
  status =
    if pool == :not_used
      send "make_request_#{ADAPTER}"
    elsif pool.is_a?(ConnectionPool)
      pool.with { |handle| make_request(handle) }
    elsif pool == TyphoeusGlobalPool
      pool.with(self) { |handle| make_request(handle) }
    else
      raise "unknown pool: #{pool}"
    end

  if VERBOSE
    puts "[#{process_id}][#{request_id}]: #{status}"
  end

  status
end

def make_request(handle)
  status = send "make_request_#{ADAPTER}", handle

  if RESET_HANDLES
    # Remove all cookies from memory for this handle
    case ADAPTER
    when :ethon
      handle.cookielist = "all"
    when :curb
      handle.setopt(Curl::CURLOPT_COOKIELIST, "all")
    end

    handle.reset
  end

  status
end

def make_request_ethon(handle = nil)
  handle ||= create_ethon_handle
  handle.http_request(URL, :get)
  handle.perform
end

def make_request_curb(handle = nil)
  handle ||= create_curb_handle
  handle.url = URL
  handle.http(:GET)
  handle.code
rescue => error
  error.to_s
end

def make_request_typhoeus
  response = Typhoeus::Request.new(URL, method: :get).run
  response.return_code
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
    title << " + tweaks" if TWEAK_HANDLES
    title << " + reset" if RESET_HANDLES

    case POOL
    when :connection_pool
      title << " + connection pool"
    when :typhoeus_global_pool
      title << " + typhoeus pool (global)"
    end
  end

  puts "#{title} | #{statuses.tally}"
end

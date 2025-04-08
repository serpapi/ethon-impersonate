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

require "parallel"
require "connection_pool"
require "pry"

require "ethon"
require "typhoeus"

ADAPTER = :ethon # :ethon, :typhoeus

REQUESTS = 1000
PROCESSES = 4
THREADS = 10

URL = "https://serpapi.com/robots.txt"

def request(process_id, request_id)
  status = send "make_request_#{ADAPTER}"

  puts "[#{process_id}][#{request_id}]: #{status}"

  status
end

def make_request_typhoeus
  response = Typhoeus.get(URL)
  response.return_code
end

def make_request_ethon(handle = nil)
  handle ||= Ethon::Easy.new
  handle.http_request(URL, :get)
  handle.perform
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

  puts "\n#{ADAPTER} | #{statuses.tally}"
end

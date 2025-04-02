require "parallel"
require "pry"

require "bundler/setup"
require "ethon"

URL = "https://serpapi.com/robots.txt"

REQUEST_COUNT = 1000
MAX_RETRIES = 3
DELAY_ON_ERROR = 1 # seconds
TARGET = "chrome131"

CONCURRENCY = 10
CONCURRENCY_MODEL = :threads # :threads or :processes

##
# [macOS]
#
# To run in processes:
# OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES ruby stress_test.rb
#
# Set higher `ulimit` to run in general:
# ulimit -n
# => 256  -- this is to low, causes `couldnt_resolve_host` error
#
# ulimit -n 4096  -- should be fine
#
# When running in threads:
# - starts throwing `bad_function_argument` error around 400-450th request
#
# When running in processes with 1 thread per process:
# - OK, no errors
#
# When running in processes with many threads per process:
# - to be tested

def run(num, retry_count = 0)
  easy = Ethon::Easy.new(url: URL)
  easy.impersonate(TARGET)
  status = easy.perform

  if status == :ok
    puts "[#{num}]: ok"
    [:ok, easy]
  else
    loop do
      retry_count += 1

      puts "[#{num}]: retry [#{retry_count}] - #{status}"

      sleep(DELAY_ON_ERROR)
      # easy = Ethon::Easy.new(url: URL)
      # easy.impersonate(TARGET)
      status = easy.perform

      if status == :ok
        puts "[#{num}]: ok"
        return [status, easy]
      end

      if retry_count >= MAX_RETRIES
        puts "[#{num}]: failed - #{status}"
        return [status, easy]
      end
    end
  end
end

failed = Parallel.map((1..REQUEST_COUNT).to_a, :"in_#{CONCURRENCY_MODEL}" => CONCURRENCY) do |num|
  status, easy = run(num)
  #       ^^ for debugging

  unless status == :ok
    [status, easy]
  end
end.compact

puts "\nOK: #{REQUEST_COUNT - failed.size}/#{REQUEST_COUNT}"

unless failed.empty?
  puts "\nFailed with errors:"

  failed_stats = failed.group_by { |status, _| status }.transform_values(&:size)

  failed_stats.each do |status, req_count|
    puts ": #{status} - #{req_count}"
  end
end

# binding.pry

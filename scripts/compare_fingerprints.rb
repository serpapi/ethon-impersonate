require "json"
require "pry"

require "bundler/setup"
require "ethon"

# URL = "https://tls.peet.ws/api/all"
URL = "https://tls.browserleaks.com/json"

TARGET = "chrome131"

def imp
  puts ": get via ethon + #{TARGET}"

  easy = Ethon::Easy.new(url: URL)
  easy.impersonate(TARGET)
  easy.perform

  JSON.parse(easy.response_body, symbolize_names: true)
end

def not_imp
  puts ": get via ethon"

  easy = Ethon::Easy.new(url: URL)
  easy.perform

  JSON.parse(easy.response_body, symbolize_names: true)
end

def imp_directly
  script_path = "../../curl-impersonate-v0.9.5.arm64-macos"
  script = "curl_#{TARGET}"

  puts ": get via curl-impersonate (#{script})"

  response = `#{script_path}/#{script} -s #{URL}`
  JSON.parse(response, symbolize_names: true)
end

imp_data = imp
not_imp_data = not_imp
imp_directly_data = imp_directly

puts "\nComparing TLS data:"

keys_to_compare = [
  :user_agent,
  :ja3n_hash,
  :ja3n_text,
  :ja4,
  :ja4_r,
]

keys_to_compare.each do |key|
  ok =
    (imp_data[key] == imp_directly_data[key]) &&
    (imp_data[key] != not_imp_data[key])

  puts ": #{key} - #{ok ? "OK" : "fail"}"
end

# binding.pry

require "ethon-impersonate"

easy = EthonImpersonate::Easy.new
get = EthonImpersonate::Easy::Http::Get.new("https://httpbin.org/ip", {})
get.setup(easy)
easy.impersonate("chrome136")
easy.perform

puts easy.response_body

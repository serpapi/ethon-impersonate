# frozen_string_literal: true
require "open-uri"
require "stringio"
require "ethon_impersonate/impersonate/settings"
require "ethon_impersonate/library_installer"

namespace :ethon_impersonate do
  desc "Download a curl-impersonate library into the app's vendor dir (usage: rake ethon_impersonate:update_lib[1.5.6])"
  task :update_lib, [:version] do |_t, args|
    settings = EthonImpersonate::Impersonate::Settings
    version = args[:version].to_s.empty? ? settings::LIB_VERSION : args[:version]
    arch_os = settings.arch_os
    os_target = arch_os.split("-").last

    begin
      release_url = settings.release_url(arch_os, version: version)
      lib_glob = settings.lib_glob(os_target)
    rescue SystemExit
      abort "ethon_impersonate: unsupported platform '#{arch_os}'. " \
        "Download a libcurl-impersonate build manually and set CURL_IMPERSONATE_LIBRARY to its path."
    end

    vendor_dir = settings.vendor_lib_dir

    puts "Downloading curl-impersonate v#{version} for #{arch_os}..."
    puts "  #{release_url}"

    begin
      archive = URI.open(release_url, &:read)
    rescue OpenURI::HTTPError => e
      abort "ethon_impersonate: download failed (#{e.message}). " \
        "Check that curl-impersonate v#{version} publishes a build for #{arch_os}."
    end

    copied = EthonImpersonate::LibraryInstaller.extract(
      StringIO.new(archive), vendor_dir, lib_glob, prune_stale: true
    )

    if copied.empty?
      abort "ethon_impersonate: no matching library found in the archive " \
        "(expected a file matching #{lib_glob.inspect})."
    end

    puts
    puts "Installed curl-impersonate v#{version}:"
    copied.each { |path| puts "  #{path}" }
    puts
    puts "The gem loads this automatically the next time the app boots."
  end
end

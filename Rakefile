# frozen_string_literal: true
require "bundler"
Bundler.setup

require "rake"
require "rspec/core/rake_task"
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "ethon_impersonate/version"
require "ethon_impersonate/impersonate/settings"

require "fileutils"
require "open-uri"
require "rubygems/package"
require "zlib"

task release: :build do
  system "git tag -a v#{EthonImpersonate::VERSION} -m 'Tagging #{EthonImpersonate::VERSION}'"
  system "git push --tags"
  system "gem push ethon-impersonate-#{EthonImpersonate::VERSION}.gem"
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
  t.ruby_opts = "-W -I./spec -rspec_helper"
end

desc "Start up the test servers"
task :start do
  require_relative 'spec/support/boot'
  begin
    Boot.start_servers(:rake)
  rescue Exception
  end
end

namespace :ethon_impersonate do
  desc "Build gem for a specific arch_os target"
  task :build, [:arch_os] do |t, args|
    abort("Please provide an arch_os target (e.g., x86_64-linux)") unless args[:arch_os]

    arch_os = args[:arch_os]
    os_target = arch_os.split("-").last

    release_url = EthonImpersonate::Impersonate::Settings.release_url(arch_os)
    release_file = EthonImpersonate::Impersonate::Settings.lib_release_file(arch_os)
    lib_names = EthonImpersonate::Impersonate::Settings.lib_names(os_target)
    ext_path = EthonImpersonate::Impersonate::Settings::LIB_EXT_PATH

    download_dir = "tmp/downloads/#{arch_os}"
    extract_dir = "tmp/extracted/#{arch_os}"
    tmp_dir = "tmp/gemspecs"

    FileUtils.mkdir_p(download_dir)
    FileUtils.mkdir_p(extract_dir)
    FileUtils.mkdir_p(tmp_dir)
    FileUtils.mkdir_p(ext_path)

    Dir.glob("ext/libcurl*").each { |path| FileUtils.rm_rf(path) }

    download_path = File.join(download_dir, release_file)

    puts "Downloading #{release_url} to #{download_path}..."
    URI.open(release_url) do |remote_file|
      File.open(download_path, 'wb') do |file|
        file.write(remote_file.read)
      end
    end

    puts "Extracting #{download_path} to #{extract_dir}..."
    Zlib::GzipReader.open(download_path) do |gz|
      Gem::Package::TarReader.new(gz) do |tar|
        tar.each do |entry|
          next unless entry.file?

          filename = File.basename(entry.full_name)

          if lib_names.any? { |lib| filename.start_with?(lib) }
            dest_path = File.join(ext_path, filename)

            FileUtils.mkdir_p(File.dirname(dest_path))
            File.open(dest_path, "wb") { |f| f.write(entry.read) }
            puts "Copied #{entry.full_name} → #{dest_path}"
          end
        end
      end
    end

    copied_libs = Dir.entries(ext_path).select do |filename|
      lib_names.any? { |lib| filename.start_with?(lib) }
    end

    if copied_libs.empty?
      abort("No matching libraries found in archive for #{arch_os}. Expected one of: #{lib_names.inspect}")
    end

    gemspec_path = Dir.glob("*.gemspec").first
    abort("Gemspec file not found!") unless gemspec_path

    gemspec = Bundler.load_gemspec(gemspec_path)

    target_gem_platforms = EthonImpersonate::Impersonate::Settings::GEM_PLATFORMS_MAP[arch_os] || [arch_os]

    puts "Building gem(s) for #{arch_os}..."

    target_gem_platforms.each do |target_gem_platform|
      temp_gemspec = gemspec.dup
      temp_gemspec.platform = target_gem_platform
      temp_gemspec.files += Dir.glob("ext/**/*")

      temp_gemspec_path = File.join(tmp_dir, "#{File.basename(gemspec_path, ".gemspec")}.#{target_gem_platform}.gemspec")
      File.write(temp_gemspec_path, temp_gemspec.to_ruby)

      system("gem build #{temp_gemspec_path} --platform #{target_gem_platform}") || abort("Gem build failed")
      puts "Gem built successfully: #{target_gem_platform}"
    end
  end

  desc "Install the gem for the current platform after building all platform-specific gems"
  task :install do
    Rake::Task["ethon_impersonate:build_all"].invoke
    Rake::Task["ethon_impersonate:build_all"].reenable

    version = EthonImpersonate::VERSION
    platform = Gem::Platform.local.to_s

    gem_filename = "ethon-impersonate-#{version}-#{platform}.gem"

    unless File.exist?(gem_filename)
      abort("Gem file not found: #{gem_filename}")
    end

    puts "Installing #{gem_filename}..."
    system("gem install ./#{gem_filename}") || abort("gem install failed")
    puts "Installed ethon-impersonate #{version} for platform #{platform}"
  end

  desc "Publish gem for a specific arch_os target"
  task :publish, [:arch_os] => [:build] do |t, args|
    abort("Please provide an arch_os target (e.g., x86_64-linux)") unless args[:arch_os]

    arch_os = args[:arch_os]
    version = EthonImpersonate::VERSION

    target_gem_platforms = EthonImpersonate::Impersonate::Settings::GEM_PLATFORMS_MAP[arch_os] || [arch_os]

    target_gem_platforms.each do |target_gem_platform|
      gem_filename = "ethon-impersonate-#{version}-#{target_gem_platform}.gem"
      abort("Gem file not found: #{gem_filename}") unless File.exist?(gem_filename)

      puts "Pushing #{gem_filename} to RubyGems..."
      system("gem push #{gem_filename}") || abort("Gem push failed!")
    end
  end

  desc "Build all platform-specific gems"
  task :build_all do
    targets = EthonImpersonate::Impersonate::Settings::LIB_PLATFORM_RELEASE_MAP.keys

    targets.each do |arch_os|
      puts "\n=== Building for #{arch_os} ==="
      Rake::Task["ethon_impersonate:build"].invoke(arch_os)
      Rake::Task["ethon_impersonate:build"].reenable
    end

    puts "All platform-specific gems built!"
  end

  desc "Publish all platform-specific gems to RubyGems"
  task :publish_all => :build_all do
    targets = EthonImpersonate::Impersonate::Settings::LIB_PLATFORM_RELEASE_MAP.keys

    targets.each do |arch_os|
      puts "\n=== Publishing for #{arch_os} ==="
      Rake::Task["ethon_impersonate:publish"].invoke(arch_os)
      Rake::Task["ethon_impersonate:publish"].reenable
    end

    puts "All platform-specific gems pushed to RubyGems!"
  end

  desc "Clean up downloaded and extracted files"
  task :clean do
    [
      Dir.glob("ext/libcurl*"),
      Dir.glob("tmp/*"),
      Dir.glob("ethon-impersonate-*.gem"),
    ].flatten.each { |path| FileUtils.rm_rf(path) }

    puts "Temporary files cleaned up."
  end
end

task default: :spec

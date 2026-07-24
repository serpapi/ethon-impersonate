# frozen_string_literal: true
require "fileutils"
require "zlib"
require "rubygems/package"

module EthonImpersonate
  module LibraryInstaller
    module_function

    # @param gzip_io [ IO ] a readable stream of gzip-compressed tar bytes
    # @param dest_dir [ String ] directory to write matched files into
    # @param lib_glob [ String ] fnmatch pattern for the library filename
    # @param prune_stale [ Boolean ] delete other files in dest_dir lib_glob
    # @return [ Array<String> ] absolute paths of the files written
    def extract(gzip_io, dest_dir, lib_glob, prune_stale: false)
      FileUtils.mkdir_p(dest_dir)
      copied = []

      Zlib::GzipReader.wrap(gzip_io) do |gz|
        Gem::Package::TarReader.new(gz) do |tar|
          tar.each do |entry|
            next unless entry.file?

            filename = File.basename(entry.full_name)
            next unless File.fnmatch?(lib_glob, filename, File::FNM_EXTGLOB)

            dest = File.join(dest_dir, filename)
            File.open(dest, "wb") { |f| f.write(entry.read) }
            copied << dest
          end
        end
      end

      if prune_stale && copied.any?
        stale = Dir.glob(File.join(dest_dir, lib_glob)) - copied
        stale.each { |path| File.delete(path) }
      end

      copied
    end
  end
end

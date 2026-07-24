# frozen_string_literal: true
require 'spec_helper'
require 'stringio'
require 'zlib'
require 'rubygems/package'
require 'tmpdir'
require 'ethon_impersonate/library_installer'

describe EthonImpersonate::LibraryInstaller do
  # Build a gzipped tar in memory mirroring a curl-impersonate release layout.
  # entries: [{ name:, body: } | { name:, target:, type: :symlink }]
  def build_archive(entries)
    raw = StringIO.new
    Zlib::GzipWriter.wrap(raw) do |gz|
      Gem::Package::TarWriter.new(gz) do |tar|
        entries.each do |e|
          if e[:type] == :symlink
            tar.add_symlink(e[:name], e[:target], 0755)
          else
            body = e.fetch(:body, "")
            tar.add_file_simple(e[:name], 0755, body.bytesize) { |io| io.write(body) }
          end
        end
      end
    end
    StringIO.new(raw.string)
  end

  describe ".extract" do
    it "extracts the real Linux library, skipping symlinks and unrelated files" do
      archive = build_archive([
        { name: "libcurl-impersonate.so.4.8.0", body: "elf-bytes" },
        { name: "libcurl-impersonate.so",   type: :symlink, target: "libcurl-impersonate.so.4.8.0" },
        { name: "libcurl-impersonate.so.4", type: :symlink, target: "libcurl-impersonate.so.4.8.0" },
        { name: "libcurl-impersonate.la",   body: "# libtool archive" },
      ])

      Dir.mktmpdir do |dir|
        copied = described_class.extract(archive, dir, "libcurl-impersonate.so*")

        expect(copied.map { |p| File.basename(p) }).to eq(["libcurl-impersonate.so.4.8.0"])
        expect(File.read(File.join(dir, "libcurl-impersonate.so.4.8.0"))).to eq("elf-bytes")
        expect(File.exist?(File.join(dir, "libcurl-impersonate.la"))).to be(false)
      end
    end

    it "matches a differently-versioned SONAME via the glob (future curl-impersonate)" do
      archive = build_archive([
        { name: "libcurl-impersonate.so.5.1.0", body: "newer-abi" },
      ])

      Dir.mktmpdir do |dir|
        copied = described_class.extract(archive, dir, "libcurl-impersonate.so*")
        expect(copied.map { |p| File.basename(p) }).to eq(["libcurl-impersonate.so.5.1.0"])
      end
    end

    it "extracts the real macOS dylib, skipping its symlink" do
      archive = build_archive([
        { name: "libcurl-impersonate.4.dylib", body: "mach-o" },
        { name: "libcurl-impersonate.dylib", type: :symlink, target: "libcurl-impersonate.4.dylib" },
      ])

      Dir.mktmpdir do |dir|
        copied = described_class.extract(archive, dir, "libcurl-impersonate*.dylib")
        expect(copied.map { |p| File.basename(p) }).to eq(["libcurl-impersonate.4.dylib"])
      end
    end

    it "returns an empty array when nothing matches" do
      archive = build_archive([{ name: "README.md", body: "hi" }])

      Dir.mktmpdir do |dir|
        expect(described_class.extract(archive, dir, "libcurl-impersonate.so*")).to eq([])
      end
    end
  end
end

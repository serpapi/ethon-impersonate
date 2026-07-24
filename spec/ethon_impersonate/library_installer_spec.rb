# frozen_string_literal: true
require 'spec_helper'
require 'stringio'
require 'zlib'
require 'rubygems/package'
require 'tmpdir'
require 'ethon_impersonate/library_installer'

describe EthonImpersonate::LibraryInstaller do

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

    context "with prune_stale: true" do
      it "deletes a previously installed library with a different SONAME" do
        archive = build_archive([
          { name: "libcurl-impersonate.so.5.1.0", body: "newer-abi" },
        ])

        Dir.mktmpdir do |dir|
          File.write(File.join(dir, "libcurl-impersonate.so.4.8.0"), "old-abi")
          File.write(File.join(dir, "unrelated.txt"), "keep me")

          copied = described_class.extract(archive, dir, "libcurl-impersonate.so*", prune_stale: true)

          expect(copied.map { |p| File.basename(p) }).to eq(["libcurl-impersonate.so.5.1.0"])
          expect(File.exist?(File.join(dir, "libcurl-impersonate.so.4.8.0"))).to be(false)
          expect(File.read(File.join(dir, "unrelated.txt"))).to eq("keep me")
        end
      end

      it "keeps a freshly overwritten library with the same filename" do
        archive = build_archive([
          { name: "libcurl-impersonate.so.4.8.0", body: "new-build" },
        ])

        Dir.mktmpdir do |dir|
          File.write(File.join(dir, "libcurl-impersonate.so.4.8.0"), "old-build")

          described_class.extract(archive, dir, "libcurl-impersonate.so*", prune_stale: true)

          expect(File.read(File.join(dir, "libcurl-impersonate.so.4.8.0"))).to eq("new-build")
        end
      end

      it "does not prune anything when the archive contained no match" do
        archive = build_archive([{ name: "README.md", body: "hi" }])

        Dir.mktmpdir do |dir|
          File.write(File.join(dir, "libcurl-impersonate.so.4.8.0"), "old-abi")

          copied = described_class.extract(archive, dir, "libcurl-impersonate.so*", prune_stale: true)

          expect(copied).to eq([])
          expect(File.read(File.join(dir, "libcurl-impersonate.so.4.8.0"))).to eq("old-abi")
        end
      end
    end
  end
end

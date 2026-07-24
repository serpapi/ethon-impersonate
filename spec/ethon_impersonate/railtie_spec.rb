# frozen_string_literal: true
require 'spec_helper'
require 'rake'
require 'tmpdir'
require 'fileutils'

describe "EthonImpersonate::Railtie" do
  around do |example|
    saved_app = (Rake.application if defined?(Rake))
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "rails"))
      File.write(File.join(dir, "rails", "railtie.rb"), <<~RUBY)
        module Rails
          class Railtie
            def self.rake_tasks(&block)
              (@rake_task_blocks ||= []) << block
            end

            def self.rake_task_blocks
              @rake_task_blocks ||= []
            end
          end
        end
      RUBY

      $LOAD_PATH.unshift(dir)
      begin
        example.run
      ensure
        $LOAD_PATH.delete(dir)
        $LOADED_FEATURES.reject! { |f| f.start_with?(dir) }
        Object.send(:remove_const, :Rails) if defined?(Rails)
        if EthonImpersonate.const_defined?(:Railtie, false)
          EthonImpersonate.send(:remove_const, :Railtie)
        end
        Rake.application = saved_app if saved_app
      end
    end
  end

  let(:railtie_path) do
    File.expand_path("../../../lib/ethon_impersonate/railtie.rb", __FILE__)
  end

  it "subclasses Rails::Railtie and registers exactly one rake_tasks block" do
    load railtie_path

    expect(EthonImpersonate::Railtie.ancestors).to include(Rails::Railtie)
    expect(EthonImpersonate::Railtie.rake_task_blocks.size).to eq(1)
  end

  it "defines the ethon_impersonate:update_lib task when the block runs" do
    load railtie_path

    Rake.application = Rake::Application.new
    EthonImpersonate::Railtie.rake_task_blocks.each(&:call)

    expect(Rake::Task.task_defined?("ethon_impersonate:update_lib")).to be(true)
  end
end

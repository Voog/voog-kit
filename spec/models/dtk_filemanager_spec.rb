require 'spec_helper'
require 'fileutils'
require 'json'
require 'ostruct'

describe Edicy::Dtk::FileManager do
  before :all do
    Dir.mkdir "TEST"
    Dir.chdir "TEST"
    @filemanager = Edicy::Dtk::FileManager.new
    @dir = Dir.new(".")
  end

  describe "#create_folders" do

    it "creates all folders in the given list" do
      @filemanager.create_folders
      folders = %w(stylesheets images assets javascripts components layouts)
      # check if the folders array is a subset of current directory's contents
      expect((@dir.entries & folders).length).to eq(folders.length)
    end
  end

  describe "#is_valid?" do
    context "with malformed data" do
      it "returns false" do
        expect(@filemanager.is_valid?("{[...  )")).to be false
      end
    end

    context "with empty" do
      it "returns false" do
        expect(@filemanager.is_valid?("{}")).to be false
      end
    end

    context "with invalid data" do
      it "returns false" do
        data = get_layouts
        data.first.delete_field("title")
        expect(@filemanager.is_valid?(data)).to be false
      end
    end

    context "with valid data" do
      it "returns true" do
        expect(@filemanager.is_valid?(get_layouts)).to be true
      end
    end
  end

  describe "#generate_manifest" do
    context "with empty data" do
      it "doesn't generate a 'manifest.json' file" do
        @filemanager.generate_manifest(Hash.new, Hash.new)
        expect(@dir.entries.include?('manifest.json')).to be false
      end
    end    

    context "with valid data" do
      let(:layouts) { get_layouts }
      let(:layout_assets) { get_layout_assets }

      it "generates a 'manifest.json' file" do
        @filemanager.generate_manifest(layouts, layout_assets)
        expect(@dir.entries.include?('manifest.json')).to be true
      end

      it "writes valid data into 'manifest.json'" do
        @filemanager.generate_manifest(layouts, layout_assets)
        @manifest = JSON.parse(File.read('manifest.json')).to_h
        expect(@manifest["layouts"].first["title"]).to eq(get_layouts.first.title)
        expect(@manifest["assets"].first["content_type"]).to eq(get_layout_assets.first.content_type)
      end
    end

    context "with invalid data" do
      let(:layouts) { "'foo: { ]" }
      let(:layout_assets) { "bar': [.. )" }

      it "returns false" do
        expect(@filemanager.generate_manifest(layouts, layout_assets)).to be false
      end
    end

  end

  after :all do
    Dir.chdir ".."
    FileUtils.rm_r "TEST"
  end
end

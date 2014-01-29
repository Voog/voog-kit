require 'spec_helper'
require 'fileutils'
require 'json'
require 'ostruct'

describe Edicy::Dtk::FileManager do
  before :all do
    Dir.mkdir 'TEST'
    Dir.chdir 'TEST'
    @filemanager = Edicy::Dtk::FileManager.new
    @dir = Dir.new('.')
  end

  describe '#create_asset' do
    before :each do
      @filemanager.create_folders
    end

    after :each do
      FileUtils.rm_r Dir['**']
      @filemanager.create_folders
    end

    context 'with no asset provided' do
      it 'does not create any new files' do
        @old_count = Dir['**/*'].length
        @filemanager.create_asset
        @new_count = Dir['**/*'].length
        expect(@new_count).to eq(@old_count)
      end
    end

    context 'with an invalid asset provided' do
      it 'does not create any new files' do
        @old_files = Dir['**/*']
        @filemanager.create_asset OpenStruct.new(filename: '', asset_type: 'stylesheet')
        @new_files = Dir['**/*']
        expect((@new_files - @old_files).count).to eq(0)
      end
    end

    context 'with a valid asset provided' do
      before :each do
        @old_files = Dir['**/*']
        @filemanager.create_asset get_layout_asset
        @new_files = Dir['**/*']
      end
      it 'creates a new file in the file system' do
        expect(@new_files.count).to eq(@old_files.count + 1)
      end

      it 'creates a file with the same contents as the provided asset' do
        expect(File.read(Dir.getwd + '/stylesheets/test.css')).to eq('test data')
      end

      it 'creates a file with the same name as the provided asset' do
        expect(@new_files - @old_files).to eq(['stylesheets/test.css'])
      end
    end
  end

  describe '#create_layout' do
    before :each do
      @filemanager.create_folders
    end

    after :each do
      FileUtils.rm_r Dir['**']
      @filemanager.create_folders
    end

    context 'with no layout provided' do
      it 'does not create any new files' do
        @old_files = Dir['**/*']
        @filemanager.create_asset
        @new_files = Dir['**/*']
        expect((@new_files - @old_files).count).to eq(0)
      end
    end

    context 'with an invalid layout provided' do
      it 'does not create any new files' do
        @old_files = Dir['**/*']
        @filemanager.create_asset OpenStruct.new('component' => nil, 'body' => false)
        @new_files = Dir['**/*']
        expect((@new_files - @old_files).count).to eq(0)
      end
    end

    context 'with a valid layout provided' do
      before :each do
        @old_files = Dir['**/*']
        @filemanager.create_layout get_layout
        @new_files = Dir['**/*']
      end

      it 'creates a new file in the file system' do
        expect(@new_files.count).to eq(@old_files.count + 1)
      end

      it 'creates a file with the same contents as the provided asset' do
        expect(File.read(Dir.getwd + '/components/test.tpl')).to eq('test body')
      end

      it 'creates a file with the same name as the provided asset' do
        expect(@new_files - @old_files).to eq(['components/test.tpl'])
      end
    end
  end

  describe '#create_folders' do

    it 'creates all folders in the given list' do
      @filemanager.create_folders
      folders = %w(stylesheets images assets javascripts components layouts)
      # check if the folders array is a subset of current directory's contents
      expect((@dir.entries & folders).length).to eq(folders.length)
    end
  end

  describe '#valid?' do
    context 'with malformed data' do
      it 'returns false' do
        expect(@filemanager.valid?('{[...  )')).to be false
      end
    end

    context 'with empty' do
      it 'returns false' do
        expect(@filemanager.valid?('{}')).to be false
      end
    end

    context 'with invalid data' do
      it 'returns false' do
        data = get_layouts
        data.first.delete_field('title')
        expect(@filemanager.valid?(data)).to be false
      end
    end

    context 'with valid data' do
      it 'returns true' do
        expect(@filemanager.valid?(get_layouts)).to be true
      end
    end
  end

  describe '#generate_manifest' do
    context 'with empty data' do
      it 'doesn\'t generate a "manifest.json" file' do
        @filemanager.generate_manifest(Hash.new, Hash.new)
        expect(@dir.entries.include?('manifest.json')).to be false
      end
    end

    context 'with valid data' do
      let(:layouts) { get_layouts }
      let(:layout_assets) { get_layout_assets }

      it 'generates a "manifest.json" file' do
        @filemanager.generate_manifest(layouts, layout_assets)
        expect(@dir.entries.include?('manifest.json')).to be true
      end

      it 'writes valid data into "manifest.json"' do
        @filemanager.generate_manifest(layouts, layout_assets)
        @manifest = JSON.parse(File.read('manifest.json')).to_h
        expect(@manifest['layouts'].first['title']).to eq(get_layouts.first.title)
        expect(@manifest['assets'].first['content_type']).to eq(get_layout_assets.first.content_type)
      end
    end

    context 'with invalid data' do
      let(:layouts) { '"foo: { ]' }
      let(:layout_assets) { 'bar": [.. )' }

      it 'returns false' do
        expect(@filemanager.generate_manifest(layouts, layout_assets)).to be false
      end
    end

  end

  describe '#add_to_manifest' do
    before do
      @filemanager.generate_manifest(get_layouts, get_layout_assets)
      @old_manifest = JSON.parse(File.read('manifest.json')).to_h
    end
    context 'with empty data' do
      it 'doesn\'t change the manifest file' do
        @filemanager.add_to_manifest
        @manifest = JSON.parse(File.read('manifest.json')).to_h
        expect(@manifest['layouts'].length).to eq(@old_manifest['layouts'].length)
      end
    end

    context 'with existing data' do
      it 'doesn\'t add a duplicate file' do
        testfiles = ['components/test_layout.tpl', 'layouts/testfile.tpl']
        @filemanager.add_to_manifest testfiles
        @manifest = JSON.parse(File.read('manifest.json')).to_h
        expect(@manifest['layouts'].length).to eq(@old_manifest['layouts'].length + testfiles.length - 1)
      end
    end

    context 'with a single valid filename' do
      it 'creates a new layout in the manifest' do
        @filemanager.add_to_manifest 'components/testfile.tpl'
        @manifest = JSON.parse(File.read('manifest.json')).to_h
        expect(@manifest['layouts'].length).to eq(2)
      end

      it 'adds the correct data for the new layout' do
        testfile = 'components/testfile.tpl'
        @filemanager.add_to_manifest testfile
        @manifest = JSON.parse(File.read('manifest.json')).to_h
        new_layout = @manifest['layouts'].last
        expect(new_layout).to eq(
          'content_type' => 'component',
          'component' => true,
          'file' => 'components/testfile.tpl',
          'layout_name' => '',
          'title' => 'Testfile'
        )
      end
    end

    context 'with multiple valid filenames' do
      it 'adds new layouts to the manifest file' do
        testfiles = ['components/testfile2.tpl', 'components/testfile3.tpl']
        @filemanager.add_to_manifest testfiles
        @manifest = JSON.parse(File.read('manifest.json')).to_h
        expect(@manifest['layouts'].length).to eq(1 + testfiles.length)
      end

      it 'adds the correct data for the new layouts' do
        testfiles = ['components/testfile2.tpl', 'layouts/testfile3.tpl']
        @filemanager.add_to_manifest testfiles
        @manifest = JSON.parse(File.read('manifest.json')).to_h
        new_layout = @manifest['layouts'].last
        expect(new_layout).to eq(
          'content_type' => 'page',
          'component' => false,
          'file' => 'layouts/testfile3.tpl',
          'layout_name' => 'testfile3',
          'title' => 'Testfile3'
        )
      end
    end
  end

  describe '#remove_from_manifest' do
    before :all do
      @filemanager.generate_manifest(get_layouts, get_layout_assets)
      @filemanager.add_to_manifest ['components/testfile2.tpl', 'layouts/testfile3.tpl']
      @old_manifest = JSON.parse(File.read('manifest.json')).to_h
    end

    context 'with empty data' do
      it 'doesn\'t remove anything from the manifest' do
        @filemanager.remove_from_manifest
        @manifest = JSON.parse(File.read('manifest.json')).to_h
        expect(@manifest['layouts'].length).to eq(@old_manifest['layouts'].length)
      end
    end

    context 'with invalid data' do
      it 'doesn\'t remove anything from the manifest' do
        @filemanager.remove_from_manifest 'files/testfile2.tpl'
        @manifest = JSON.parse(File.read('manifest.json')).to_h
        expect(@manifest['layouts'].length).to eq(@old_manifest['layouts'].length)
      end
    end

    context 'with valid data' do
      it 'removes the provided layouts from the manifest' do
        @filemanager.remove_from_manifest ['components/testfile2.tpl', 'layouts/testfile3.tpl']
        @manifest = JSON.parse(File.read('manifest.json')).to_h
        expect(@manifest['layouts'].length).to eq(@old_manifest['layouts'].length - 2)
      end
    end
  end

  describe '#check' do
    context 'with an empty folder' do
      it 'returns false' do
        expect(@filemanager.check false, false).to be_false
      end
    end

    context 'with empty manifest.json but no files' do
      it 'returns false' do
        File.open('manifest.json', 'w+') do |file|
          file << {
            'layouts' => [],
            'assets' => []
          }.to_json
        end
        expect(@filemanager.check false, false).to be_false
      end
    end

    context 'with filled manifest.json but no files' do
      it 'returns false' do
        File.open('manifest.json', 'w+') do |file|
          file << {
            'layouts' => [{
              "component" => false,
              "content_type" => "page",
              "file" => "layouts/front_page.tpl",
              "layout_name" => "page_front",
              "title" => "Front page"
            }],
            'assets' => []
          }.to_json
        end
        expect(@filemanager.check false, false).to be_false
      end
    end

    context 'with valid manifest.json and files' do

      context 'with no site.json' do
        it 'returns false' do
          FileUtils.mkdir('layouts') unless Dir.exists? 'layouts'
          File.open('layouts/front_page.tpl', 'w+')
          expect(@filemanager.check false, false).to be_false
        end
      end

      context 'with site.json, but wrong layout files' do
        it 'returns false' do
          File.open('site.json', 'w+') do |file|
            file << {
              "site" => {
                "root" => {
                  "pages" => [{
                    "layout" => "Other layout"
                  }]
                }
              }
            }.to_json
          end
          expect(@filemanager.check false, false).to be_false
        end
      end

      context 'with site.json and correct layout files' do
        it 'returns true' do
          File.open('site.json', 'w+') do |file|
            file << {
              "site" => {
                "root" => {
                  "pages" => [{
                    "layout" => "Front page"
                  }]
                }
              }
            }.to_json
          end
          expect(@filemanager.check false, false).to be_true
        end
      end
    end
  end

  after :all do
    Dir.chdir '..'
    FileUtils.rm_r 'TEST'
  end
end

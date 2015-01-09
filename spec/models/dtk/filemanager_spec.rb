require 'spec_helper'
require 'fileutils'
require 'json'
require 'ostruct'

describe Voog::Dtk::FileManager do
  before :all do
    Dir.mkdir 'TEST'
    Dir.chdir 'TEST'
    @filemanager = Voog::Dtk::FileManager.new(nil, {silent: true, verbose: true, overwrite: false})
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
        @manifest = @filemanager.read_manifest
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
      @old_manifest = @filemanager.read_manifest
    end
    context 'with empty data' do
      it 'doesn\'t change the manifest file' do
        @filemanager.add_to_manifest
        @manifest = @filemanager.read_manifest
        expect(@manifest['layouts'].length).to eq(@old_manifest['layouts'].length)
      end
    end

    context 'with existing data' do
      it 'doesn\'t add a duplicate file' do
        testfiles = ['components/test_layout.tpl', 'layouts/testfile.tpl']
        @filemanager.add_to_manifest testfiles
        @manifest = @filemanager.read_manifest
        expect(
          @manifest['layouts'].select { |l| l['file'] == 'components/test_layout.tpl'}.length
        ).to eq(1)
      end
    end

    context 'with a single valid filename' do
      it 'creates a new layout in the manifest' do
        @filemanager.add_to_manifest 'components/testfile.tpl'
        @manifest = @filemanager.read_manifest
        expect(@manifest['layouts'].length).to eq(2)
      end

      it 'adds the correct data for the new layout' do
        testfile = 'components/testfile.tpl'
        @filemanager.add_to_manifest testfile
        @manifest = @filemanager.read_manifest
        new_layout = @manifest['layouts'].find{|l| l['file'] == testfile}
        layout = {
          'content_type' => 'component',
          'component' => true,
          'file' => 'components/testfile.tpl',
          'layout_name' => 'testfile',
          'title' => 'testfile'
        }
        expect(new_layout).to eq(layout)
      end
    end

    context 'with multiple valid filenames' do
      it 'adds new layouts to the manifest file' do
        testfiles = ['components/testfile2.tpl', 'components/testfile3.tpl']
        @filemanager.add_to_manifest testfiles
        @manifest = @filemanager.read_manifest
        expect(@manifest['layouts'].length).to eq(1 + testfiles.length)
      end

      it 'adds the correct data for the new layouts' do
        testfiles = ['components/testfile2.tpl', 'layouts/testfile3.tpl']
        @filemanager.add_to_manifest testfiles
        @manifest = @filemanager.read_manifest
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

    context 'with both valid and invalid filenames' do
      it 'adds only valid files to the manifest' do
        @old_manifest = @filemanager.read_manifest
        testfiles = ['components/testfile2.tpl', 'javascripts/testfile.js', 'invalid/file']
        @filemanager.add_to_manifest testfiles
        @manifest = @filemanager.read_manifest
        expect(@manifest['layouts'].length).to eq(@old_manifest['layouts'].length + 1)
        expect(@manifest['assets'].length).to eq(@old_manifest['assets'].length + 1)
      end

      it 'does not add invalid files to the manifest' do

      end
    end
  end

  describe '#in_manifest?' do
    before :all do
      @manifest = JSON.parse(File.read(FIXTURE_PATH + '/manifest.json'))
    end
    context 'with a valid filename' do
      it 'returns true if the file is in the manifest' do
        filename = 'components/test_component.tpl'
        expect(@filemanager.in_manifest?(filename, @manifest)).to eq(true)
      end
      it 'returns false if the file is not in the manifest' do
        filename = 'components/wrong_file.tpl'
        expect(@filemanager.in_manifest?(filename, @manifest)).to eq(false)
      end
    end
  end

  describe '#is_asset?' do
    before :all do
      @filemanager.create_folders
      @filemanager.create_asset get_layout_asset
    end

    context 'with a valid asset filename' do
      it 'returns true' do
        expect(@filemanager.is_asset? 'stylesheets/test.css').to eq(true)
      end
    end

    context 'with an invalid asset filename' do
      it' returns false' do
        expect(@filemanager.is_asset? 'layouts/front_page.tpl').to eq(false)
      end
    end
  end

  describe '#is_layout?' do
    before :all do
      @filemanager.create_layout get_layout
    end
    context 'with a valid layout filename' do
      it 'returns true' do
        expect(@filemanager.is_layout? 'components/test.tpl').to eq(true)
      end
    end

    context 'with an invalid layout filename' do
      it' returns false' do
        expect(@filemanager.is_layout? 'javascripts/main.min.js').to eq(false)
      end
    end
  end

  describe '#remove_local_file' do
    before :each do
      @filemanager.create_asset get_layout_asset
    end

    context 'with an existing file' do
      it 'removes the file' do
        old_asset_count = Dir['stylesheets/*'].count
        @filemanager.remove_local_file 'stylesheets/test.css'
        new_asset_count = Dir['stylesheets/*'].count
        expect(old_asset_count - new_asset_count).to eq(1)
      end
      it 'returns true' do
        expect(@filemanager.remove_local_file 'stylesheets/test.css').to eq(true)
      end
    end

    context 'with an invalid filename' do
      it 'doesn\'t remove anything' do
        old_asset_count = Dir['stylesheets/*'].count
        @filemanager.remove_local_file 'stylesheets/style.css'
        new_asset_count = Dir['stylesheets/*'].count
        expect(old_asset_count - new_asset_count).to eq(0)
      end

      it 'returns false' do
        expect(@filemanager.remove_local_file 'stylesheets/style.css').to eq(false)
      end

    end
  end

  describe '#remove_from_manifest' do
    before :all do
      @filemanager.generate_manifest(get_layouts, get_layout_assets)
      @filemanager.add_to_manifest ['components/testfile2.tpl', 'assets/test.svg']
      @old_manifest = @filemanager.read_manifest
    end

    context 'with empty data' do
      it 'doesn\'t remove anything from the manifest' do
        @filemanager.remove_from_manifest
        @manifest = @filemanager.read_manifest
        expect(@manifest['layouts'].length).to eq(@old_manifest['layouts'].length)
      end
    end

    context 'with invalid data' do
      it 'doesn\'t remove anything from the manifest' do
        @filemanager.remove_from_manifest 'files/testfile2.tpl'
        @manifest = @filemanager.read_manifest
        expect(@manifest['layouts'].length).to eq(@old_manifest['layouts'].length)
      end
    end

    context 'with valid data' do
      it 'removes the provided layouts from the manifest' do
        @filemanager.remove_from_manifest ['components/testfile2.tpl', 'assets/test.svg']
        @manifest = @filemanager.read_manifest
        expect(@manifest['layouts'].length).to eq(@old_manifest['layouts'].length - 1)
        expect(@manifest['assets'].length).to eq(@old_manifest['assets'].length - 1)
      end
    end
  end

  describe '#check' do
    context 'with an empty folder' do
      before :all do
        Dir.mkdir('temp')
        Dir.chdir('temp')
      end

      after :all do
        Dir.chdir('..')
        Dir.delete('temp')
      end
      it 'returns false' do
        expect(@filemanager.check).to eq(false)
      end
    end

    context 'with empty manifest.json and no files' do
      it 'returns true' do
        File.open('manifest.json', 'w+') do |file|
          file << {
            'layouts' => [],
            'assets' => []
          }.to_json
        end
        expect(@filemanager.check).to eq(true)
      end
    end

    context 'with filled manifest.json but no files' do
      it 'returns false' do
        @manifest = File.open('manifest.json', 'w+') do |file|
          file << {
            'layouts' => [{
              'component' => false,
              'content_type' => 'page',
              'file' => "layouts/front_page.tpl",
              'layout_name' => 'page_front',
              'title' => "Front page"
            }],
            'assets' => []
          }.to_json
        end
        expect(@filemanager.check).to eq(false)
      end
    end
  end

  describe '#generate_local_manifest' do
    before :each do
      Dir.mkdir 'TEST'
      Dir.chdir 'TEST'
    end

    after :each do
      Dir.chdir '..'
      FileUtils.rm_r 'TEST'
    end

    context 'with no local files or folders' do
      before :each do
        @dir = Dir.new('.')
        @prev_entries = @dir.entries
      end

      after :each do
        FileUtils.rm 'manifest.json' if File.exists? 'manifest.jsons'
      end

      it 'returns false' do
        expect(@filemanager.generate_local_manifest).to eq(false)
      end

      it 'doesn\'t generate a manifest.json file' do
        @filemanager.generate_local_manifest
        expect(@dir.entries.length).to eq(@prev_entries.length)
      end
    end

    context 'with empty folders' do
      before :each do
        FileUtils.mkdir 'layouts'
        FileUtils.mkdir 'components'
      end

      after :each do
        FileUtils.rm_r 'layouts'
        FileUtils.rm_r 'components'
        FileUtils.rm_r 'manifest.json' if File.exists? 'manifest.json'
      end

      it 'generates a manifest file' do
        @filemanager.generate_local_manifest
        expect(File.exists? 'manifest.json').to eq(true)
        @manifest = @filemanager.read_manifest
      end

      it 'adds no layouts or components to the manifest' do
        @filemanager.generate_local_manifest
        @manifest = @filemanager.read_manifest
        expect(@manifest['layouts'].length).to eq(0)
      end

      it 'returns true' do
        expect(@filemanager.generate_local_manifest).to eq(true)
      end
    end

    context 'with layout files' do
      before :each do
        FileUtils.mkdir ('layouts')
        FileUtils.mkdir ('components')
        File.open('layouts/front_page.tpl', 'w+')
      end

      after :each do
        FileUtils.rm('layouts/front_page.tpl')
        FileUtils.rm_r 'layouts'
        FileUtils.rm_r 'components'
      end

      it 'adds the files to the manifest' do
        @filemanager.generate_local_manifest
        @manifest = @filemanager.read_manifest
        expect(@manifest['layouts'].length).to eq(1)
      end

      it 'adds the files in a correct format to the manifest' do
        @filemanager.generate_local_manifest
        @manifest = @filemanager.read_manifest
        layout = @manifest['layouts'].first
        expect(layout['component']).to eq(false)
        expect(layout['content_type']).to eq('page')
        expect(layout['file']).to eq('layouts/front_page.tpl')
        expect(layout['layout_name']).to eq('page_default')
        expect(layout['title']).to eq('Front page')
      end

      it 'returns true' do
        expect(@filemanager.generate_local_manifest).to eq(true)
      end
    end
  end

  describe '#fetch_boilerplate' do
    context 'with no files in the working directory' do
      before :each do
        @prev_files = Dir['*']
      end

      after :each do
        Dir['*'].each do |f|
          FileUtils.rm_r f
        end
      end

      it 'downloads and copies the boilerplate files' do
        @filemanager.fetch_boilerplate
        @files = Dir['*']
        expected_files = [
          'assets', 'images',
          'components', 'javascripts',
          'layouts', 'stylesheets',
          'manifest.json'
        ]
        expect(expected_files & @files).to eq(expected_files)
      end

      it 'removes the \'tmp\' directory' do
        @filemanager.fetch_boilerplate
        @files = Dir['*']
        expect(@files.include? 'tmp').to eq(false)
      end

      it 'returns true' do
        expect(@filemanager.fetch_boilerplate).to eq(true)
      end
    end

    context 'with files in the working directory' do
      before :all do
        @prev_files = Dir['*']
        File.open('test.txt', 'w+')
        File.open('manifest.json', 'w+') do |file| file << "[]" end
        @old_manifest = File.open('manifest.json')
        Dir.mkdir('test')
        @return_value = @filemanager.fetch_boilerplate
        @manifest = File.open('manifest.json')
      end

      after :all do
        Dir['*'].each do |f|
          FileUtils.rm_r f
        end
      end

      it 'overwrites existing files' do
        expect(@old_manifest.size).not_to eq(@manifest.size)
      end

      it 'doesn\'t modify other files' do
        expect(@old_manifest.stat.mtime).not_to eq(@manifest.stat.mtime)
      end

      it 'returns true' do
        expect(@return_value).to eq(true)
      end
    end
  end

  describe '#valid_for_folder?' do
    it 'returns true for valid folder+filename combinations' do
      testfiles = {
        'stylesheets' => ['style.css', 'style.min.css'],
        'javascripts' => ['script.js', 'script.min.js'],
        'images' => ['image.jpg', 'image.png'],
        'assets' => ['icon.svg', 'text.txt'],
        'components' => ['menu.tpl'],
        'layouts' => ['front_page.tpl']
      }

      testfiles.each do |folder, files|
        files.each do |filename|
          expect(@filemanager.valid_for_folder? filename, folder).to be_true
        end
      end
    end

    it 'returns false for invalid folder+filename combinations' do
      testfiles = {
        'stylesheets' => ['style.css.map', 'style.scss', 'style.less'],
        'javascripts' => ['script.js.map', 'script.coffee'],
        'images' => ['icon.svg'],
        'assets' => ['.gitignore'],
        'components' => ['test', 'style.css'],
        'layouts' => ['test', 'script.js']
      }

      testfiles.each do |folder, files|
        files.each do |filename|
          expect(@filemanager.valid_for_folder? filename, folder).to be_false
        end
      end
    end
  end

  after :all do
    Dir.chdir '..'
    FileUtils.rm_r 'TEST'
  end
end

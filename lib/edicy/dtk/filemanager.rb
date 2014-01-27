require 'edicy_api'
require 'net/http'
require 'json'
require 'colorize'
require 'fileutils'

module Edicy::Dtk
  class FileManager
    def add_to_manifest(files = nil)
      return if files.nil?
      @manifest = JSON.parse(File.read('manifest.json')).to_h
      files = (files.is_a? String) ? [files] : files
      files.uniq.each do |file|
        match = /^(component|layout)s\/(.*)/.match(file)
        type, filename = match[1], match[2] unless match.nil?
        count = @manifest['layouts'].count { |item| item['file'] == file }
        next if count > 0
        if type && filename
          component = type == 'component'
          layout = {
            content_type: component ? 'component' : 'page',
            component: component,
            file: file,
            layout_name: component ? '' : filename.split('.').first,
            title: filename.split('.').first.gsub('_', ' ').capitalize
          }
        end
        @manifest['layouts'] << layout
        puts "Added #{file} to manifest.json"
      end
      File.open('manifest.json', 'w+') { |file| file << @manifest.to_json }
    end

    def remove_from_manifest(files = nil)
      return if files.nil?
      @manifest = JSON.parse(File.read('manifest.json')).to_h
      files = (files.is_a? String) ? [files] : files
      files.uniq.each do |file|
        @manifest['layouts'].delete_if do |layout|
          match = layout['file'] == file
          puts "Removed #{file} from manifest.json" if match
          match
        end
      end
      File.open('manifest.json', 'w+') do |file|
        file << @manifest.to_json
      end
    end

    def get_layouts
      layouts = Edicy.layouts
      layouts.length ? layouts : false
    end

    def get_layout_assets
      layout_assets = Edicy.layout_assets
      layout_assets.length ? layout_assets : false
    end

    def get_layout(id)
      Edicy.layout id
    end

    def get_layout_asset(id)
      Edicy.layout_asset id
    end

    def get_layout(id)
      Edicy.layout id
    end

    def valid?(item)
      if item.is_a? String
        begin
          valid? JSON.parse(item)
        rescue
          false
        end
      else
        if item.is_a? Array
          item.each do |subitem|
            return valid? subitem
          end
        else
          if item.respond_to?('[]') && item.respond_to?('key?')
            return ( %w(title content_type component).map do |key|
              item.key? key
            end.all? || %w(asset_type content_type filename).map do |key|
              item.key? key
            end.all?)
          else
            return ( %i(title content_type component).map do |key|
              item.respond_to?(key)
            end.all? || %i(asset_type content_type filename).map do |key|
              item.respond_to?(key)
            end.all?)
          end
        end
      end
    end

    def generate_manifest(layouts = nil, layout_assets = nil)
      layouts = layouts || get_layouts
      layout_assets = layout_assets || get_layout_assets

      return false unless layouts && layout_assets && !layouts.empty? && !layout_assets.empty?
      return false unless valid?(layouts) && valid?(layout_assets)

      File.open('manifest.json', 'w+') do |file|
        manifest = Hash.new
        manifest[:layouts] = layouts.inject(Array.new) do |memo, l|
          memo << {
            title: l.title,
            layout_name: l.title.gsub(/[^\w\.\-]/, '_').downcase,
            content_type: l.content_type,
            component: l.component,
            file: "#{(l.component ? 'components' : 'layouts')}/#{l.title.gsub(/[^\w\.\-]/, '_').downcase}.tpl"
          }
        end

        manifest[:assets] = layout_assets.inject(Array.new) do |memo, a|
          memo << {
            kind: a.asset_type,
            filename: a.filename,
            file: "#{a.asset_type}s/#{a.filename}",
            content_type: a.content_type
          }
        end
        file << JSON.dump(manifest)
      end
    end

    def create_folders
      folders = %w(stylesheets images assets javascripts components layouts)
      folders.each { |folder| Dir.mkdir(folder) unless Dir.exists?(folder) }
    end

    def create_files(layouts = nil, layout_assets = nil)
      if layouts.nil? && layout_assets.nil?
        layouts = get_layouts
        layout_assets = get_layout_assets
      end
      create_layouts(layouts.map(&:id))
      create_assets(layout_assets.map(&:id))
    end

    def create_assets(ids)
      ids.uniq.each do |id|
        create_asset(get_layout_asset id)
      end
    end

    def create_asset(asset = nil)
      return unless asset &&
        asset.respond_to?(:asset_type) &&
        asset.respond_to?(:filename) &&
        (asset.respond_to?(:public_url) || asset.respond_to?(:data))

      folder_names = {
        'image' => 'images',
        'stylesheet' => 'stylesheets',
        'javascript' => 'javascripts',
        'font' => 'assets',
        'unknown' => 'assets'
      }
      Dir.chdir(folder_names.fetch(asset.asset_type, 'assets'))
      if %w(stylesheet javascript).include? asset.asset_type
        open(asset.filename, 'wb') { |file| file.write(asset.data) }
      else
        url = URI(asset.public_url)
        Net::HTTP.start(url.hostname) do |http|
          resp = http.get(url.path)
          open(asset.filename, 'wb') { |file| file.write(resp.body) }
        end
      end
      Dir.chdir('..')
    end

    def create_layouts(ids)
      ids.each do |id|
        create_layout get_layout id
      end
    end

    def create_layout(layout = nil)
      return unless layout &&
        layout.respond_to?(:component) &&
        layout.respond_to?(:title) &&
        layout.respond_to?(:body)

      Dir.chdir(layout.component ? 'components' : 'layouts')
      File.open("#{layout.title.gsub(/[^\w\.\-]/, '_').downcase}.tpl", 'w') { |file| file.write layout.body }
      Dir.chdir('..')
    end

    def data_directory
      File.join(File.dirname(File.expand_path(__FILE__)), '../../../data')
    end

    def copy_site_json
      cwd = Dir.getwd
      FileUtils.cp data_directory + '/site.json', cwd
    end

    def check
      # ok_char = "\u2713".encode('utf-8')
      # not_ok_char = "\u2717".encode('utf-8')
      ok_char = "."
      not_ok_char = "!"
      delay = 0.05

      puts 'Checking for manifest.json ...'.white
      $stdout.sync = true

      # Check for manifest
      if File.exists? 'manifest.json'
        @manifest = JSON.parse(File.read('manifest.json')).to_h
        puts "OK!".green
      else
        puts 'Manifest file not found! Use the \'manifest\' command to generate one.'.red
        return false
      end

      # Check for folders
      puts "Checking for folders ...".white
      folders = %w(stylesheets images assets javascripts components layouts)
      missing_folders = %w()
      folders.each do |folder|
        sleep delay
        if Dir.exists? folder
          print ok_char.green
        else
          missing_folders << folder
          print not_ok_char.red
        end
      end

      print " "

      if missing_folders.count > 0
        if missing_folders.count == folders.count
          puts "All folders are missing.".red
        else
          puts "Some folders are missing.".red
        end
        puts "Please run the 'init' command to create the initial folder structure.".white
        return false
      else
        puts " OK!".green
      end

      # Check for files in manifest
      layouts = @manifest['layouts']
      missing_layouts = %w()

      puts "Checking layouts ...".white
      layouts.each do |layout|
        sleep delay
        if File.exists? layout['file']
          print ok_char.green
        else
          missing_layouts << layout['file']
          print not_ok_char.red
        end
      end

      print " "

      if missing_layouts.count > 0
        print "Found #{missing_layouts.count} missing layout files.".red
      else
        puts "OK!".green
      end

      assets = @manifest['assets']
      missing_assets = %w()

      puts "Checking assets ...".white
      assets.each do |asset|
        sleep delay
        if File.exists? asset['file']
          print ok_char.green
        else
          missing_assets << asset['file']
          print not_ok_char.red
        end
      end

      print " "

      if missing_assets.count > 0
        puts "\nFound #{missing_assets.count} missing layout assets:".red
        missing_assets.each { |a| print "  "; puts a }
      else
        puts "OK!".green
      end
    end
  end
end

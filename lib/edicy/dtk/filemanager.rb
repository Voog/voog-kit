require 'edicy_api'
require 'net/http'
require 'json'
require 'colorize'
require 'fileutils'
require 'git'

module Edicy::Dtk
  class FileManager

    def initialize(client, verbose=false, silent=false)
      @client = client
      @verbose = verbose
      @silent = silent
    end

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
        puts "Added #{file} to manifest.json".white unless @silent
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
          puts "Removed #{file} from manifest.json".white if (match && !@silent)
          match
        end
      end
      File.open('manifest.json', 'w+') do |file|
        file << @manifest.to_json
      end
    end

    def get_layouts
      layouts = @client.layouts
      layouts.length ? layouts : false
    end

    def get_layout_assets
      layout_assets = @client.layout_assets
      layout_assets.length ? layout_assets : false
    end

    def get_layout(id)
      @client.layout id
    end

    def get_layout_asset(id)
      @client.layout_asset id
    end

    def get_layout(id)
      @client.layout id
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
              (item.key? key) || (item.key? key.to_sym)
            end.all? || %w(asset_type content_type filename).map do |key|
              (item.key? key) || (item.key? key.to_sym)
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

    def generate_local_manifest(verbose=false, silent=false)
      unless %w(layouts components).map { |f| Dir.exists? f }.all?
        puts 'No local files found to generate manifest from!'.red unless @silent
        return false
      end

      puts 'Reading local files...'.white unless @silent
      layouts_dir = Dir.new('layouts')
      layouts = layouts_dir.entries.select do |file|
        file =~ /(.*)\.tpl/
      end
      layouts = layouts.map do |l|
        {
          "content_type" =>  "page",
          "component" => false,
          "file" => "layouts/#{l}",
          "layout_name" => "page_default",
          "title" => l.split(".").first.gsub('_', " ").capitalize
        }
      end
      components_dir = Dir.new('components')
      components = components_dir.entries.select do |file|
        file =~/(.*)\.tpl/
      end
      components = components.map do |c|
        {
          "content_type" => "component",
          "component" => true,
          "file" => "components/#{c}",
          "layout_name" => "",
          "title" => c.split(".").first.gsub('_', ' ')
        }
      end
      assets = []
      asset_dirs = %w(assets images javascripts stylesheets)
      asset_dirs.each do |dir|
        next unless Dir.exists? dir
        current_dir = Dir.new(dir)
        current_dir.entries.each do |file|
          extension = file.split('.').last
          content_types = {
            "assets" => "unknown/unknown",
            "images" => "image/#{extension}",
            "javascripts" => "text/javascript",
            "stylesheets" => "text/css"
          }
          next if file =~ /^\.\.?$/
          assets << {
            "content_type" => case dir
              when 'images'
                "image/#{extension}"
              when 'javascripts'
                'text/javascript'
              when 'stylesheets'
                'text/css'
              else
                'unknown/unknown'
              end,
            "file" => "#{dir}/#{file}",
            "kind" => dir,
            "filename" => file
          }
        end
      end
      manifest = {
        "description" => "New design",
        "name" => "New design",
        "preview_medium" => "",
        "preview_small" => "",
        "author" => "",
        "layouts" => layouts + components,
        "assets" => assets
      }
      puts 'Writing layout files to new manifest.json file...'.white unless @silent
      File.open('manifest.json', 'w+') do |file|
        file << manifest.to_json
      end
      return true
    end

    def generate_remote_manifest
      generate_manifest get_layouts, get_layout_assets
    end

    def generate_manifest(layouts = nil, layout_assets = nil)
      layouts = layouts || get_layouts
      layout_assets = layout_assets || get_layout_assets

      unless (layouts && layout_assets && !layouts.empty? && !layout_assets.empty?)
        puts 'No remote layouts found to generate manifest from!'.red unless @silent
        return false
      end

      unless valid?(layouts) && valid?(layout_assets)
        puts 'No valid layouts found to generate manifest from!'.red unless @silent
        return false
      end

      puts 'Reading remote layouts...'.white unless @silent
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
        folder = if %w(unknown font).include? a.asset_type
          "assets"
        else
          "#{a.asset_type}s"
        end
        memo << {
          kind: a.asset_type,
          filename: a.filename,
          file: "#{folder}/#{a.filename}",
          content_type: a.content_type
        }
      end
      puts 'Writing remote layouts to new manifest.json file...'.white unless @silent
      File.open('manifest.json', 'w+') do |file|
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

    def copy_site_json(verbose=false, silent=false)
      if File.exists? data_directory + '/site.json'
        FileUtils.cp data_directory + '/site.json', Dir.getwd
        puts 'site.json copied to current working directory'.white unless @silent
      else
        raise 'site.json not found in gem\'s data files!'.red unless @silent
      end
    end

    def check(verbose=false, silent=false)
      # ok_char = "\u2713".encode('utf-8')
      # not_ok_char = "\u2717".encode('utf-8')
      ok_char = "."
      not_ok_char = "!"
      delay = 0.005

      puts 'Checking for manifest.json'.white unless @silent
      $stdout.sync = true

      # Check for manifest
      if File.exists? 'manifest.json'
        @manifest = JSON.parse(File.read('manifest.json')).to_h
        puts "OK!".green unless @silent
      else
        puts 'Manifest file not found! Use the \'manifest\' command to generate one.'.red unless @silent
        return false
      end

      print "\n" unless @silent

      # Check for files in manifest
      layouts = @manifest['layouts']
      missing_layouts = %w()

      puts "Checking layouts and components".white unless @silent
      layouts.each do |layout|
        sleep delay
        if File.exists? layout['file']
          print ok_char.green unless @silent
        else
          missing_layouts << layout['file']
          print not_ok_char.red unless @silent
        end
      end

      if missing_layouts.count > 0
        puts "\nFound #{missing_layouts.count} missing layout files.".red unless @silent
        missing_layouts.each { |l| print "  "; puts l } unless @silent && !@verbose
      else
        puts "OK!".green unless @silent
      end

      assets = @manifest['assets']
      missing_assets = %w()

      print "\n" unless @silent

      puts "Checking assets".white unless @silent
      assets.each do |asset|
        sleep delay
        if File.exists? asset['file']
          print ok_char.green unless @silent
        else
          missing_assets << asset['file']
          print not_ok_char.red unless @silent
        end
      end

      if missing_assets.count > 0
        puts "\nFound #{missing_assets.count} missing layout assets.".red unless @silent
        missing_assets.each { |a| print "  "; puts a } unless @silent && !@verbose 
      else
        puts "OK!".green unless @silent
      end

      puts "\nChecking for site.json".white unless @silent
      if File.exists? 'site.json'
        @site = JSON.parse(File.read('site.json')).to_h
        puts "OK!".green unless @silent
      else
        puts 'site data file not found!' unless @silent
        return false
      end

      puts "\nChecking for page layouts".white unless @silent
      pages = @site['site']['root']['pages']
      pages += @site['site']['root']['children'] if @site['site']['root']['children']

      pages.map do |n|
        n['pages']
      end.flatten

      page_layouts = pages.map { |p| p['layout'] }.uniq.select { |l| !l.nil? }

      existing_layouts = @manifest['layouts'].select { |l| !l['component'] }.map { |l| l['title'] }.uniq

      all_page_layouts_present = ((page_layouts & existing_layouts) == page_layouts)

      if all_page_layouts_present
        puts "OK!".green unless @silent
      elsif (page_layouts & existing_layouts).length == 0
        puts 'None of the page layouts found!'.red unless @silent
        if @verbose && !@silent
          puts 'Missing:'
          puts page_layouts
        end
        return false
      else
        puts 'Not all page layouts found!'.yellow unless @silent
        if @verbose && !@silent
          puts 'Missing:'
          puts (page_layouts - existing_layouts).map { |l| "  " + l }
        end
        return false
      end
      return true
    end

    def fetch_boilerplate(dst='tmp')
      puts 'Fetching design boilerplate...'.white unless @silent

      FileUtils.rm_r 'tmp' if Dir.exists? 'tmp'

      begin
        Git.clone 'git@github.com:Edicy/design-boilerplate.git', dst
      rescue
        puts 'An error ocurred!'.red unless @silent
        return false
      end

      if Dir.exists? 'tmp'
        Dir.chdir 'tmp'
        puts 'Copying boilerplate files to working directory...'.white unless @silent
        Dir.new('.').entries.each do |f|
          unless f =~ /^\..*$/
            if Dir.exists?('../' + f) || File.exists?('../' + f)
              FileUtils.rm_r '../' + f
            end
            FileUtils.mv f, '..'
          end
        end
        Dir.chdir '..'
        FileUtils.rm_r 'tmp'
      end
      puts 'Done!'.green unless @silent
      return true
    end

    # Returns filename=>id hash for layout files
    def layout_id_map
      remote_layouts = @client.layouts.inject(Hash.new) do |memo, l|
        memo[l.title.downcase] = l.id
        memo
      end
      @manifest = JSON.parse(File.read('manifest.json')).to_h
      a = @manifest.fetch('layouts').inject(Hash.new) do |memo, l|
        memo[l['file']] = remote_layouts.fetch(l['title'].downcase, nil)
        memo
      end
    end

    # Returns filename=>id hash for layout assets
    def layout_asset_id_map
      @client.layout_assets.inject(Hash.new) do |memo, a|
        memo[a.public_url.gsub("http://#{@client.host}/", '')] = a.id
        memo
      end
    end

    def upload_files(files)
      return unless files.length

      layout_assets = layout_asset_id_map
      # layouts = layout_id_map

      files.each do |file|
        if File.exist? file
          if %w(layouts components).include? file.split('/').first
            print "Updating layout file #{file}...".white unless @silent
            if layouts.key? file
              update_layout(layouts[file], File.read(file))
              print "OK!\n".green unless @silent
            else
              print "Remote file not found!\n".red unless @silent
            end
          else
            print "Updating layout asset file #{file}...".white unless @silent
            if layout_assets.key? file
              if is_editable?(file)
                if update_layout_asset(layout_assets[file], File.read(file))
                  print "OK!\n".green unless @silent
                else
                  print "Unable to update file!\n".red unless @silent
                end
              else
                print "Unable to update file!\n".red unless @silent
              end
            else
              print "Remote file not found!\n".red unless @silent
              print "\nTrying to create file #{file}...".white unless @silent
              if create_remote_file(file)
                print "OK!\n".green unless @silent
                add_to_manifest(file)
              else
                print "Unable to create file!\n".red unless @silent
              end
            end
          end
        else
          print "File #{file} not found!\n".red unless @silent
        end
      end
    end

    def is_editable?(file)
      folder = file.split('/').first
      extension = file.split('/').last.split('.').last

      (%w(stylesheets javascripts).include? folder) && (%w(js css).include? extension)
    end

    def content_type_for(file)
      folder = file.split('/').first
      if is_editable?(file)
        if folder == 'stylesheets'
          'text/css'
        elsif folder == 'javascripts'
          'text/javascript'
        end
      else
        if folder == 'images'
          "image/#{file.split("/").last.split(".").last}"
        elsif folder == 'assets'
          'unknown/unknown'
        end
      end
    end

    def create_remote_file(file)
      data = {
        filename: file.split('/').last,
        content_type: content_type_for(file)
      }

      if is_editable?(file)
        data[:data] = File.read(file)
      else
        data[:file] = file
      end

      @client.create_layout_asset(data)
    end

    def update_layout(id, data)
      @client.update_layout(id, body: data)
    end

    def update_layout_asset(id, data)
      @client.update_layout_asset(id, data: data)
    end
  end
end

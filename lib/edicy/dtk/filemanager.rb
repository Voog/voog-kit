require 'edicy_api'
require 'net/http'
require 'json'
require 'fileutils'
require 'git'

module Edicy::Dtk
  class FileManager

    def initialize(client, verbose=false, silent=false)
      @notifier = Edicy::Dtk::Notifier.new($stderr, silent)
      @client = client
      @verbose = verbose
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
        @notifier.info "Added #{file} to manifest.json"
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
          @notifier.info "Removed #{file} from manifest.json" if match
          match
        end
      end
      File.open('manifest.json', 'w+') do |file|
        file << @manifest.to_json
      end
    end

    def get_layouts
      @client.layouts
    end

    def get_layout_assets
      @client.layout_assets
    end

    def get_layout(id)
      @client.layout id
    end

    def get_layout_asset(id)
      @client.layout_asset id
    end

    def update_layout(id, data)
      @client.update_layout(id, body: data)
    end

    def update_layout_asset(id, data)
      @client.update_layout_asset(id, data: data)
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
        @notifier.error 'No layout files found to generate manifest from!'
        return false
      end

      @notifier.info 'Reading local files...'
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
      @notifier.info 'Writing layout files to new manifest.json file...'
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
        @notifier.error 'No remote layouts found to generate manifest from!'
        return false
      end

      unless valid?(layouts) && valid?(layout_assets)
        @notifier.error 'No valid layouts found to generate manifest from!'
        return false
      end

      @notifier.info 'Reading remote layouts...'
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
      @notifier.info 'Writing remote layouts to new manifest.json file...'
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
      folder = folder_names.fetch(asset.asset_type, 'assets')
      Dir.mkdir(folder) unless Dir.exists?(folder)
      Dir.chdir(folder)
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
        @notifier.info 'site.json copied to current working directory'
      else
        @notifier.error 'site.json not found in gem\'s data files!'
      end
    end

    def check
      # ok_char = "\u2713".encode('utf-8')
      # not_ok_char = "\u2717".encode('utf-8')
      ok_char = "."
      not_ok_char = "!"
      @notifier.newline
      @notifier.info "Checking manifest.json..."

      # Check for manifest
      if File.exists? 'manifest.json'
        @manifest = JSON.parse(File.read('manifest.json')).to_h
        @notifier.success 'OK!'
      else
        @notifier.error 'Manifest file not found! Use the \'manifest\' command to generate one.'
        return false
      end

      # Check for files in manifest
      layouts = @manifest['layouts']
      missing_layouts = %w()

      @notifier.newline
      @notifier.info "Checking layouts and components"
      layouts.each do |layout|
        if File.exists? layout['file']
          @notifier.success ok_char
        else
          missing_layouts << layout['file']
          @notifier.error not_ok_char
        end
      end

      if missing_layouts.count > 0
        @notifier.error " (#{missing_layouts.count} missing)"
        @notifier.newline
        missing_layouts.each do |a|
          @notifier.normal "    #{a}"
          @notifier.newline
        end if @verbose
      else
        @notifier.success 'OK!'
      end

      assets = @manifest['assets']
      missing_assets = %w()

      @notifier.newline
      @notifier.info "Checking assets"
      assets.each do |asset|
        if File.exists? asset['file']
          @notifier.success ok_char
        else
          missing_assets << asset['file']
          @notifier.error not_ok_char
        end
      end

      if missing_assets.count > 0
        @notifier.error " (#{missing_assets.count} missing)"
        @notifier.newline
        missing_assets.each do |a|
          @notifier.normal "    #{a}"
          @notifier.newline
        end if @verbose
      else
        @notifier.success 'OK!'
      end
    end

    def fetch_boilerplate(dst='tmp')
      @notifier.info 'Fetching design boilerplate...'

      FileUtils.rm_r 'tmp' if Dir.exists? 'tmp'

      begin
        Git.clone 'git@github.com:Edicy/design-boilerplate.git', dst
      rescue
        @notifier.error 'An error occurred!'
        return false
      end

      if Dir.exists? 'tmp'
        Dir.chdir 'tmp'
        @notifier.info 'Copying boilerplate files to working directory...'
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
      @notifier.success 'Done!'
      return true
    end

    # Returns filename=>id hash for layout files
    def layout_id_map
      remote_layouts = @client.layouts.inject(Hash.new) do |memo, l|
        memo[l.title.downcase] = l.id
        memo
      end
      @manifest = JSON.parse(File.read('manifest.json')).to_h if File.exists? 'manifest.json'
      fail "Manifest not found! (See `edicy help manifest` for more info)".red unless @manifest
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
      layouts = layout_id_map

      files.each do |file|
        if File.exist? file
          if %w(layouts components).include? file.split('/').first
            @notifier.info "Updating layout file #{file}..."
            if layouts.key? file
              update_layout(layouts[file], File.read(file))
              @notifier.success "OK!\n"
            else
              @notifier.error "Remote file not found!\n"
            end
          else
            @notifier.info "Updating layout asset file #{file}..."
            if layout_assets.key? file
              if is_editable?(file)
                if update_layout_asset(layout_assets[file], File.read(file))
                  @notifier.success "OK!\n"
                else
                  @notifier.error "Unable to update file!\n"
                end
              else
                @notifier.error "Unable to update file!\n"
              end
            else
              @notifier.error "Remote file not found!"
              @notifier.info "\nTrying to create file #{file}..."
              if create_remote_file(file)
                @notifier.success "OK!\n"
                add_to_manifest(file)
              else
                @notifier.error "Unable to create file!\n"
              end
            end
          end
        else
          @notifier.error "File #{file} not found!\n"
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

    def find_layouts(names)
      layouts = get_layouts
      @manifest = JSON.parse(File.read('manifest.json')).to_h if File.exist? 'manifest.json'
      results = []

      names.each do |name|
        name = name.split('/').last.split('.').first
        if @manifest
          layout = @manifest['layouts'].find{ |l| l['file'].split('/').last.split('.').first == name }
          if layout # layout file is in manifest
            layout = layouts.find{ |l| l.title == layout['title'] }
          else # not found in manifest
            layout = layouts.find{ |l| l.title == name }
          end
          id = layout.id if layout
        else
          layout = layouts.find{ |l| l.title.gsub(/[^\w\.]/, '_').downcase == name}
          id = layout['id'] if layout
        end
        results << id if id
      end

      results
    end

    def find_assets(names)
      assets = get_layout_assets
      results = []
      names.each do |name|
        name = name.split('/').last
        layout = assets.find{ |l| l.filename == name }
        results << layout.id if layout
      end
      results
    end

    def pull_files(names)
      layout_ids = find_layouts(names)
      asset_ids = find_assets(names)

      create_layouts(layout_ids) if layout_ids.length
      create_assets(asset_ids) if asset_ids.length
    end
  end
end

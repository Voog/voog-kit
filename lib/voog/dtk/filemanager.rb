require 'voog_api'
require 'net/http'
require 'json'
require 'fileutils'
require 'git'
require 'mime/types'

module Voog::Dtk
  class FileManager
    attr_accessor :notifier

    BOILERPLATE_URL = 'git@github.com:Edicy/design-boilerplate.git'

    def initialize(client, opts = {})
      @client = client
      @silent = opts.fetch(:silent, false)
      @verbose = opts.fetch(:verbose, false)
      @overwrite = opts.fetch(:overwrite, false)
      @cleanup = opts.fetch(:cleanup, false)
      @notifier = Voog::Dtk::Notifier.new($stderr, @silent)
    end

    def read_manifest
      JSON.parse(File.read('manifest.json', encoding: 'UTF-8')).to_h
    end

    def write_manifest(manifest)
      File.open('manifest.json', 'w+', encoding: 'UTF-8') do |file|
        file << JSON.pretty_generate(manifest)
      end
    end

    def in_manifest?(file, manifest = nil)
      @manifest = manifest || read_manifest
      filenames = @manifest['layouts'].map { |l| l.fetch('file', '') }
      filenames += @manifest['assets'].map { |a| a.fetch('filename', '') }
      filenames.include? file
    end

    def valid_for_folder?(filename, folder)
      return false unless (filename && folder)

      # discard dotfiles
      return false if filename.match(/\A[\.]{1}.+\z/)

      mimetype = MIME::Types.of(filename).first
      media_type = mimetype.media_type if mimetype
      sub_type = mimetype.sub_type if mimetype

      case folder
      when 'images'
        # SVG files are assets, not images
        (media_type == 'image') && (sub_type != 'svg+xml')
      when 'javascripts'
        # Allow only pure JS files
        (media_type == 'application') && (sub_type == 'javascript')
      when 'stylesheets'
        # Only pure CSS files, not SCSS/LESS etc.
        (media_type == 'text') && (sub_type == 'css')
      when 'layouts'
        # Allow only files with .tpl extension
        /\A[^\.]+\.tpl\z/.match(filename) && true
      when 'components'
        # Allow only files with .tpl extension
        /\A[^\.]+\.tpl\z/.match(filename) && true
      else
        true
      end
    end

    def add_to_manifest(files = nil)
      return if files.nil?
      @manifest = read_manifest

      new_layouts = []
      new_assets = []

      files = (files.is_a? String) ? [files] : files
      files.uniq.each do |file|
        next if in_manifest?(file, @manifest)

        match = /^(component|layout|image|javascript|asset|stylesheet)s\/(.*)/.match(file)
        next if match.nil?

        type, filename = match[1], match[2]

        unless valid_for_folder?(filename, "#{type}s")
          @notifier.error "Invalid filename '#{filename}' for '#{type}s' folder. Skipping.\n"
          next
        end

        if %w(component layout).include? type
          component = type == 'component'
          name = filename.split('.').first
          title = component ? name : name.gsub('_', ' ').capitalize

          layout = {
            'title' => component ? name : title,
            'layout_name' => name,
            'content_type' => component ? 'component' : 'page',
            'component' => component,
            'file' => file
          }

          new_layouts << layout
        elsif %w(image javascript asset stylesheet).include? type
          asset = {
            'content_type' => begin
              MIME::Types.type_for(filename).first.content_type
            rescue
              'text/unknown'
            end,
            'kind' => "#{type}s",
            'file' => file,
            'filename' => filename
          }

          new_assets << asset
        end

        @notifier.info "Added #{file} to manifest.json"
        @notifier.newline
      end

      new_layouts.map { |l| @manifest['layouts'] << l }
      new_assets.map { |a| @manifest['assets'] << a }

      write_manifest @manifest

      # returns all successfully added files
      new_layouts + new_assets
    end

    def remove_from_manifest(files = nil)
      return if files.nil?
      @manifest = read_manifest
      files = (files.is_a? String) ? [files] : files
      files.uniq.each do |file|
        match = /^(component|layout|image|javascript|asset|stylesheet)s\/(.*)/.match(file)
        next if match.nil?
        type, filename = match[1], match[2]
        if %w(component layout).include? type
          @manifest['layouts'].delete_if do |layout|
            match = layout.fetch('file', nil) == file
            @notifier.info "Removed #{file} from manifest.json" if match
            match
          end
        elsif %w(image javascript asset stylesheet).include? type
          @manifest['assets'].delete_if do |asset|
            match = asset.fetch('file', nil) == file
            @notifier.info "Removed #{file} from manifest.json" if match
            match
          end
        end
        @notifier.newline
      end
      write_manifest @manifest
    end

    def get_layouts
      @client.layouts(per_page: 10_000)
    end

    def get_layout_assets
      @client.layout_assets(per_page: 10_000)
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

    def delete_layout(id)
      @client.delete_layout(id)
    end

    def delete_layout_asset(id)
      @client.delete_layout_asset(id)
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

    def generate_local_manifest(verbose = false, silent=false)
      unless %w(layouts components).map { |f| Dir.exist? f }.all?
        @notifier.error 'Missing local layout folders! (See `kit help init`)'
        return false
      end

      begin
        @old_manifest = JSON.parse(File.read('manifest.json', encoding: 'UTF-8')).to_h if File.exist? 'manifest.json'
      rescue JSON::ParserError
        @notifier.error 'Invalid JSON in current manifest file!'
        @notifier.newline
      end

      @notifier.info 'Reading local files...'
      layouts_dir = Dir.new('layouts')
      layouts = layouts_dir.entries.select do |file|
        (!File.directory?(File.join(layouts_dir, file)) && valid_for_folder?(file, 'layouts'))
      end
      layouts = layouts.map do |l|
        attrs = {
          'content_type' =>  'page',
          'component' => false,
          'file' => "layouts/#{l}",
          'layout_name' => 'page_default',
          'title' => l.split('.').first.gsub('_', ' ').capitalize
        }
        if @old_manifest && @old_manifest.fetch('layouts')
          old_layout = @old_manifest.fetch('layouts').select { |ol| ol.fetch('file').gsub('layouts/', '') == l }.first || {}
          attrs.merge! old_layout
        end
        attrs
      end
      components_dir = Dir.new('components')
      components = components_dir.entries.select do |file|
        (!File.directory?(File.join(components_dir, file)) && valid_for_folder?(file, 'components'))
      end
      components = components.map do |c|
        name = c.split('.').first.gsub('_', ' ')
        attrs = {
          'content_type' => 'component',
          'component' => true,
          'file' => "components/#{c}",
          'layout_name' => name,
          'title' => name
        }
        if @old_manifest && @old_manifest.fetch('layouts')
          old_component = @old_manifest.fetch('layouts').select { |ol| ol.fetch('file').gsub('components/', '') == c }.first || {}
          attrs.merge! old_component
        end
        attrs
      end
      assets = []
      asset_dirs = %w(assets images javascripts stylesheets)
      asset_dirs.each do |dir|
        next unless Dir.exist? dir
        current_dir = Dir.new(dir)
        current_dir.entries.each do |file|
          next unless !File.directory?(File.join(current_dir, file)) && valid_for_folder?(file, dir)
          attrs = {
            'content_type' => begin
              MIME::Types.type_for(file).first.content_type
            rescue
              'text/unknown'
            end,
            'file' => "#{dir}/#{file}",
            'kind' => dir,
            'filename' => file
          }
          if @old_manifest && @old_manifest.fetch('assets')
            old_asset = @old_manifest.fetch('assets').select { |ol| ol.fetch('filename') == file }.first || {}
            attrs.merge! old_asset
          end
          assets << attrs
        end
      end

      manifest = {
        'description' => "New design",
        'name' => "New design",
        'preview_medium' => "",
        'preview_small' => "",
        'author' => "",
        'layouts' => sort_layouts_by_content_type(layouts + components),
        'assets' => assets
      }
      if @old_manifest
        old_meta = @old_manifest.tap{ |m| m.delete('assets') }.tap{ |m| m.delete('layouts') }
        manifest.merge! old_meta
      end
      @notifier.newline
      @notifier.info 'Writing layout files to new manifest.json file...'
      write_manifest(manifest)
      @notifier.success 'Done!'
      @notifier.newline
      true
    end

    def generate_remote_manifest
      generate_manifest get_layouts, get_layout_assets
    end

    def sort_layouts_by_content_type(layouts)
      # make sure that 'blog' is before 'blog_article' and 'elements' is before 'element'
      preferred_order = %w(page blog blog_article elements element error_401 error_404 photoset component)

      layouts.sort do |a, b|
        preferred_order.index(a.fetch('content_type')) <=> preferred_order.index(b.fetch('content_type'))
      end
    end

    def generate_manifest(layouts = nil, layout_assets = nil)
      layouts ||= get_layouts
      layout_assets ||= get_layout_assets

      # type->folder map for layout assets
      asset_folders = {
        'asset' => 'assets',
        'javascript' => 'javascripts',
        'stylesheet' => 'stylesheets',
        'image' => 'images'
      }

      if (layouts.empty? && layout_assets.empty?)
        @notifier.error 'No remote layouts found to generate manifest from!'
        @notifier.newline
        return false
      end

      unless valid?(layouts) && valid?(layout_assets)
        @notifier.error 'No valid layouts found to generate manifest from!'
        @notifier.newline
        return false
      end

      @notifier.info 'Writing remote layouts to new manifest.json file...'

      manifest = {}

      manifest[:layouts] = layouts.inject(Array.new) do |memo, l|
        memo << {
          'title' => l.title,
          'layout_name' => l.title.gsub(/[^\w\.\-]/, '_').downcase,
          'content_type' => l.content_type,
          'component' => l.component,
          'file' => "#{(l.component ? 'components' : 'layouts')}/#{l.title.gsub(/[^\w\.\-]/, '_').downcase}.tpl"
        }
      end

      manifest[:layouts] = sort_layouts_by_content_type(manifest[:layouts])

      manifest[:assets] = layout_assets.inject(Array.new) do |memo, a|

        # kind is same as asset_type for kinds that are represented in the asset_folders hash, defaults to 'asset'
        kind = asset_folders.key?(a.asset_type.to_s) ? a.asset_type : 'asset'
        folder = asset_folders.fetch(kind, 'assets')

        memo << {
          'kind' => kind,
          'filename' => a.filename,
          'file' => "#{folder}/#{a.filename}",
          'content_type' => a.content_type
        }
      end

      write_manifest(manifest)
      @notifier.success 'Done!'
      @notifier.newline
    end

    def create_folders
      @notifier.newline
      @notifier.info 'Creating folder structure...'
      folders = %w(stylesheets images assets javascripts components layouts)
      folders.each { |folder| Dir.mkdir(folder) unless Dir.exist?(folder) }
      @notifier.success 'Done!'
      @notifier.newline
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
      @notifier.info "Creating assets#{'...' if @verbose}"
      ids.uniq.each do |id|
        create_asset(get_layout_asset id)
      end
      @notifier.newline if @verbose
      @notifier.success 'Done!'
      @notifier.newline
    end

    def create_asset(asset = nil)
      valid = asset && asset.respond_to?(:asset_type) \
        && asset.respond_to?(:filename) \
        && asset.respond_to?(:asset_type) \
        && (asset.respond_to?(:public_url) || asset.respond_to?(:data))

      folder_names = {
        'image' => 'images',
        'stylesheet' => 'stylesheets',
        'javascript' => 'javascripts',
        'font' => 'assets',
        'unknown' => 'assets'
      }

      if valid
        folder = folder_names.fetch(asset.asset_type, 'assets')

        Dir.mkdir(folder) unless Dir.exist?(folder)
        Dir.chdir(folder)

        overwritten = File.exist? asset.filename

        if @verbose
          @notifier.newline
          if overwritten
            @notifier.warning "  + #{folder}/#{asset.filename}"
          else
            @notifier.success "  + #{folder}/#{asset.filename}"
          end
        else
          @notifier.success '.'
        end

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
      else
        @notifier.error '!' unless @verbose
      end
    end

    def create_layouts(ids)
      @notifier.info "Creating layouts#{'...' if @verbose}"
      ids.each do |id|
        create_layout get_layout id
      end
      @notifier.newline if @verbose
      @notifier.success 'Done!'
      @notifier.newline
    end

    def create_layout(layout = nil)
      valid = layout &&
        layout.respond_to?(:component) &&
        layout.respond_to?(:title) &&
        layout.respond_to?(:body)

      if valid
        folder = layout.component ? 'components' : 'layouts'
        filename = "#{layout.title.gsub(/[^\w\.\-]/, '_').downcase}.tpl"
        Dir.chdir(folder)
        overwritten = File.exist? filename

        if @verbose
          @notifier.newline
          if overwritten
            @notifier.warning "  + #{folder}/#{filename}"
          else
            @notifier.success "  + #{folder}/#{filename}"
          end
        else
          @notifier.success '.'
        end

        File.open(filename, 'w') { |file| file.write layout.body }

        Dir.chdir('..')
      else
        @notifier.error '!' unless @verbose
      end
    end

    def check
      ok_char = '.'
      not_ok_char = '!'
      @notifier.info 'Checking manifest.json...'

      if File.exist? 'manifest.json'
        @manifest = read_manifest
        @notifier.success 'OK!'
      else
        @notifier.error 'Manifest file not found! Use the \'manifest\' command to generate one.'
        return false
      end

      # Check for files in manifest
      layouts = @manifest.fetch('layouts', [])
      missing_layouts = %w()

      @notifier.newline
      @notifier.info 'Checking layouts and components'
      layouts.reject(&:nil?).each do |layout|
        if File.exist? layout['file']
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
      @notifier.info 'Checking assets'
      assets.reject(&:nil?).each do |asset|
        if File.exist? asset['file']
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

      (missing_assets.count + missing_layouts.count == 0)
    end

    def clone_design(url = BOILERPLATE_URL, dst = 'tmp')
      # Allow only design repositories from Edicy/Voog for now
      pattern = /\Ahttps?:\/\/github.com\/(?:Voog|Edicy)\/design-(\w+)\.git\z/ # HTTPS clone URL
      pattern2 = /\Agit@github.com:(?:Voog|Edicy)\/design-(\w+)\.git\z/ # SSH clone URL

      match = url.match(pattern) || url.match(pattern2)

      unless match.nil?
        @notifier.info "Fetching the #{match[1].capitalize} design..."
        @notifier.newline
      else
        # default to the boilerplate URL if given URL doesn't match the Regex pattern
        @notifier.info 'Fetching design boilerplate...'
        @notifier.newline
        url = BOILERPLATE_URL
      end

      FileUtils.rm_r 'tmp' if Dir.exist? 'tmp'

      begin
        Git.clone url, dst
      rescue
        @notifier.error 'An error occurred!'
        return false
      end

      if Dir.exist? 'tmp'
        Dir.chdir 'tmp'
        @notifier.info 'Copying template files to working directory...'
        @notifier.newline
        Dir.new('.').entries.each do |f|
          unless f =~ /^\..*$/
            if Dir.exist?('../' + f) || File.exist?('../' + f)
              FileUtils.rm_r '../' + f
            end
            FileUtils.mv f, '..'
          end
        end
        Dir.chdir '..'
        FileUtils.rm_r 'tmp'
      end
      @notifier.success 'Done!'
      @notifier.newline
      true
    end

    # Returns filename=>id hash for layout files
    def layout_id_map(layouts = nil)
      layouts ||= get_layouts
      remote_layouts = layouts.inject(Hash.new) do |memo, l|
        memo[l.title.downcase] = l.id
        memo
      end

      @manifest = read_manifest
      fail 'Manifest not found! (See `kit help push` for more info)'.red unless @manifest
      layouts = @manifest.fetch('layouts').reject(&:nil?)
      layouts.inject(Hash.new) do |memo, l|
        remote_exist = remote_layouts.key?(l.fetch('title').downcase)
        memo[l.fetch('file')] = remote_layouts.fetch(l.fetch('title').downcase, nil) if remote_exist
        memo
      end
    end

    # Returns filename=>id hash for layout assets
    def layout_asset_id_map(assets=nil)
      assets ||= get_layout_assets
      assets.inject(Hash.new) do |memo, a|
        memo[a.public_url.gsub("http://#{@client.host}/", '')] = a.id
        memo
      end
    end

    def upload_files(files)
      if files.length == 0
        @notifier.info "Pushing all files...\n"
        files = %w(layouts components stylesheets javascripts images assets)
      end

      layout_assets = layout_asset_id_map
      layouts = layout_id_map

      # Find if provided file is a directory instead
      files.each_with_index do |file, index|
        next if file.is_a? Array
        if Dir.exist? file
          subfiles = Dir.new(file).entries.reject{|e| e =~ /^(\.|\.\.)$/ } # Keep only normal subfiles
          subfiles.map! { |subfile| subfile = "#{file[/[^\/]*/]}/#{subfile}" } # Prepend folder name
          files[index] = subfiles # Insert as Array so sub-subfolders won't get processed again
        end
      end
      files.flatten! # If every folder is processed, flatten the array

      @manifest = read_manifest
      local_layouts = @manifest.fetch('layouts', []).reject(&:nil?).map{ |l| l.fetch('file','') }
      local_assets = @manifest.fetch('assets', []).reject(&:nil?).map{ |a| a.fetch('file','') }

      files.each_with_index do |file, index|
        @notifier.newline if index > 0
        if File.exist?(file)
          if uploadable?(file)
            if file =~ /^(layout|component)s\/[^\s\/]+\.tpl$/ # if layout/component
              if local_layouts.include?(file)
                if layouts.key?(file)
                  @notifier.info "Updating layout file #{file}..."
                  if update_layout(layouts[file], File.read(file, encoding: 'UTF-8'))
                    @notifier.success 'OK!'
                  else
                    @notifier.error "Cannot update layout file #{file}!"
                  end
                else
                  @notifier.warning "Remote file #{file} not found!"
                  @notifier.info "\nTrying to create layout file #{file}..."
                  if create_remote_layout(file)
                    @notifier.success 'OK!'
                  else
                    @notifier.error "Unable to create layout file #{file}!"
                  end
                end
              else
                @notifier.warning "Layout file #{file} not found in manifest! Skipping."
              end
            elsif file =~ /^(asset|image|stylesheet|javascript)s\/[^\s\/]+\..+$/ # if other asset
              if local_assets.include? file
                if layout_assets.key? file
                  if is_editable?(file)
                    @notifier.info "Updating layout asset file #{file}..."
                    if update_layout_asset(layout_assets[file], File.read(file, encoding: 'UTF-8'))
                      @notifier.success 'OK!'
                    else
                      @notifier.error "Unable to update file #{file}!"
                    end
                  else
                    if @overwrite
                      @notifier.info "Re-uploading file #{file}..."
                      if delete_layout_asset(layout_assets[file]) && create_remote_file(file)
                        @notifier.success 'OK!'
                      else
                        @notifier.error "Unable to update file #{file}!"
                      end
                    else
                      @notifier.warning "Not allowed to update file #{file}!"
                    end
                  end
                else
                  @notifier.warning "Remote file #{file} not found!"
                  @notifier.info "\nTrying to create file #{file}..."
                  if create_remote_file(file)
                    @notifier.success 'OK!'
                  else
                    @notifier.error "Unable to create file #{file}!"
                  end
                end
              else
                @notifier.warning "Asset file #{file} not found in manifest! Skipping."
              end
            elsif Dir.exist? file
              @notifier.warning "Not allowed to push subfolder #{file}!"
            else
              @notifier.warning "Not allowed to push file #{file}!"
            end
          else
            @notifier.error "Cannot upload file #{file}!"
          end
        else
          @notifier.error "File #{file} not found!"
        end
      end
      @notifier.newline
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
          "image/#{file.split('/').last.split('.').last}"
        elsif folder == 'assets'
          'unknown/unknown'
        end
      end
    end

    def create_remote_layout(file)
      @manifest = read_manifest if File.exist? 'manifest.json'
      layouts = @manifest.fetch('layouts', []).reject(&:nil?)
      layout = layouts.select { |l| file == l.fetch('file') }.first

      if @manifest && layouts && layout
        data = {
          title: layout.fetch('title'),
          content_type: layout.fetch('content_type'),
          component: layout.fetch('component'),
          body: File.exist?(layout.fetch('file')) ? File.read(layout.fetch('file'), encoding: 'UTF-8') : ''
        }
      else
        name = file.split('/').last.split('.').first
        component = (file.split('/').first =~ /^layouts$/).nil?
        body = File.read(file, encoding: 'UTF-8')
        data = {
          title: component ? name : name.capitalize,
          content_type: 'page',
          component: component,
          body: body
        }
      end

      @client.create_layout(data)
    end

    def create_remote_file(file)
      data = {
        filename: file.split('/').last,
        content_type: content_type_for(file)
      }

      if is_editable?(file)
        data[:data] = File.read(file, encoding: 'UTF-8')
      else
        data[:file] = file
      end

      @client.create_layout_asset(data)
    end

    def is_asset?(filename)
      asset_folders = %w(assets images stylesheets javascripts)
      asset_folders.include?(filename.split('/').first)
    end

    def is_layout?(filename)
      layout_folders = %w(components layouts)
      layout_folders.include?(filename.split('/').first)
    end

    def remove_files(names)
      names.each do |name|
        remove_local_file(name) if File.file?(name)
        remove_remote_file(name)
        remove_from_manifest(name)
        @notifier.newline
      end
    end

    def add_files(names)
      new_files = add_to_manifest names
      upload_files new_files.map { |f| f.fetch('file') } unless new_files.empty?
    end

    def remove_local_file(file)
      if File.exist?(file) && File.delete(file)
        @notifier.info "Removed local file #{file}." unless @silent
        @notifier.newline
        return true
      else
        @notifier.error "Failed to remove file #{file}." unless @silent
        @notifier.newline
        return false
      end
    end

    def remove_remote_file(file)
      folder, filename = file.split('/')
      return unless (folder && filename)

      asset_ids = layout_asset_id_map
      layout_ids = layout_id_map

      if is_asset? file
        id = asset_ids.fetch(file, nil)

        unless id.nil?
          if delete_layout_asset(id)
            @notifier.info "Removed remote asset '#{filename}'." unless @silent
          else
            @notifier.error "Failed to remove remote asset '#{filename}'!" unless @silent
          end
        end
      elsif is_layout? file
        filename = filename.gsub('.tpl', '')
        id = layout_ids.fetch(file, nil)

        unless id.nil?
          if delete_layout(id)
            @notifier.info "Removed remote layout '#{filename}'." unless @silent
          else
            @notifier.error "Failed to remove remote layout '#{file}'!" unless @silent
          end
        end
      else
        @notifier.error "Invalid filename: '#{file}'"
      end
      @notifier.newline
    end

    def uploadable?(file)
      if file.is_a? String
        !(file =~ /^(component|layout|image|asset|javascript|stylesheet)s\/([^\s]+)/).nil?
      else
        begin
          uploadable? file.try(:to_s)
        rescue
          raise "Cannot upload file '#{file}'!".red
        end
      end
    end

    def find_layouts(names)
      layouts = get_layouts
      results = []

      names.each do |name|
        case name
        when /\Alayouts\/?\Z/
          results << layouts.select { |l| !l.component }.map(&:id)
        when /\Acomponents\/?\Z/
          results << layouts.select { |l| l.component }.map(&:id)
        else
          type, name = name.gsub('.tpl', '').split('/')
          results << layouts.select do |l|
            (type == 'layouts' ? !l.component : l.component) && l.title.gsub(/[^\w\.]/, '_').downcase == name
          end.map(&:id)
        end
      end
      results.flatten
    end

    def find_assets(names)
      assets = get_layout_assets
      results = []
      names.each do |name|
        case name
        when /\Aassets\/?\Z/
          results << assets.select { |a| a.asset_type == 'asset' }.map(&:id)
        when /\Aimages\/?\Z/
          results << assets.select { |a| a.asset_type == 'image' }.map(&:id)
        when /\Ajavascripts\/?\Z/
          results << assets.select { |a| a.asset_type == 'javascript' }.map(&:id)
        when /\Astylesheets\/?\Z/
          results << assets.select { |a| a.asset_type == 'stylesheet' }.map(&:id)
        else
          results << assets.select { |a| a.filename == name.split('/').last }.map(&:id)
        end
      end
      results.flatten
    end

    def pull_files(names)
      layout_ids = find_layouts(names)
      asset_ids = find_assets(names)

      found = layout_ids.length + asset_ids.length

      unless found
        @notifier.error "Unable to find any files matching the given pattern#{'s' if names.length > 1}!"
        @notifier.newline
        ret = false
      else
        ret = true
      end

      create_layouts(layout_ids) unless layout_ids.empty?
      create_assets(asset_ids) unless asset_ids.empty?

      ret
    end

    def display_sites(sites)
      sites.each_with_index do |site, index|
        @notifier.info "#{site.fetch(:name)} #{'(default)' if index == 0}"
        if @verbose
          @notifier.newline
          @notifier.info "  host: #{site.fetch(:host)}"
          @notifier.newline
          @notifier.info "  token: #{site.fetch(:api_token)}"
        end
        @notifier.newline
      end
    end
  end
end

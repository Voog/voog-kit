require 'edicy_api'
require 'net/http'
require 'json'

module Edicy::Dtk

  class FileManager

    def add_to_manifest(files)
      @manifest = JSON.parse(File.read('manifest.json')).to_h
      files.each do |file|
        match = /^(component|layout)s\/(.*)/.match(file)
        type, filename = match[1], match[2]
        component = type == "component"
        layout = {
          :content_type => component ? "component" : "page",
          :component => component,
          :file => file,
          :layout_name => component ? "" : filename.split(".").first,
          :title => filename.split(".").first.gsub("_", " ").capitalize
        }
        @manifest["layouts"] << layout
        puts "Added #{file} to manifest.json"
      end
      File.open('manifest.json', 'w+') do |file|
        file << @manifest.to_json
      end
    end

    def remove_from_manifest(files)
      @manifest = JSON.parse(File.read('manifest.json')).to_h
      files.each do |file|
        @manifest["layouts"].delete_if { |layout|
          match = layout["file"] == file
          puts "Removed #{file} from manifest.json" if match
          match
        }
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

    def is_valid?(item)
      if item.is_a? String
        begin
          is_valid? JSON.parse(item)
        rescue
          false
        end
      else
        if item.is_a? Array
          item.each do |subitem|
            return is_valid? subitem
          end
        else
          if item.respond_to?("[]") && item.respond_to?("key?")
            return ( %w(title content_type component).map { |key|
              item.key? key
            }.all? || %w(asset_type content_type filename).map { |key|
              item.key? key
            }.all? )
          else
            return ( %i(title content_type component).map { |key|
              item.respond_to?(key)
            }.all? || %i(asset_type content_type filename).map { |key|
              item.respond_to?(key)
            }.all? )
          end
        end
      end
    end

    def generate_manifest(layouts=nil, layout_assets=nil)
      layouts = layouts || get_layouts
      layout_assets = layout_assets || get_layout_assets
      unless (layouts && layout_assets && !layouts.empty? && !layout_assets.empty?) then return false end

      unless (is_valid?(layouts) && is_valid?(layout_assets)) then return false end

      File.open("manifest.json", "w+") do |file|
        manifest = Hash.new
        manifest[:layouts] = layouts.inject(Array.new) do |memo, l|
          memo << {
            :title => l.title,
            :layout_name => l.title.gsub(/[^\w\.\-]/, '_').downcase,
            :content_type => l.content_type,
            :component => l.component,
            :file => "#{(l.component ? "components" : "layouts")}/#{l.title.gsub(/[^\w\.\-]/, '_').downcase}.tpl"
          }
        end

        manifest[:assets] = layout_assets.inject(Array.new) do |memo, a|
          memo << {
            :kind => a.asset_type,
            :filename => a.filename,
            :file => "#{a.asset_type}s/#{a.filename}",
            :content_type => a.content_type
          }
        end
        file << JSON.dump(manifest)
      end
    end

    def create_folders
      folders = %w(stylesheets images assets javascripts components layouts)
      folders.each { |folder| Dir.mkdir(folder) unless Dir.exists?(folder) }
    end

    def create_files
      create_layouts(get_layouts.map(&:id))
      create_assets(get_layout_assets.map(&:id))
    end

    def create_assets(ids)
      ids.each do |id|
        la = Edicy.layout_asset id
        folder_names = {
          "image" => "images",
          "stylesheet" => "stylesheets",
          "javascript" => "javascripts"
        }
        Dir.chdir(folder_names.fetch(la.asset_type, "assets"))
        if %w(stylesheet javascript).include? la.asset_type
          open(la.filename, "wb") do |file|
            file.write(la.body)
          end
        else
          url = URI(la.public_url)
          Net::HTTP.start(url.hostname) do |http|
            resp = http.get(url.path)
            open(la.filename, "wb") do |file|
             file.write(resp.body)
            end
          end
        end

        Dir.chdir('..')
      end
    end

    def create_layouts(ids)
      ids.each do |id|
        l = Edicy.layout(id)
        Dir.chdir(l.component ? 'components' : 'layouts')
        File.open("#{l.layout_name}.tpl", "w") do |file|
          file.write l.body
        end
        Dir.chdir('..')
      end
    end

  end
end

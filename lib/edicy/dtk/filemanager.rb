require 'edicy_api'
require 'net/http'

module Edicy::Dtk
  
  class FileManager

    def initialize

    end

    def create_folders
      folders = %w(stylesheets images assets javascripts components layouts)
      folders.each { |folder| Dir.mkdir(folder) unless Dir.exists?(folder) }
    end

    def create_files
      create_layouts(Edicy.layouts.map(&:id))
      create_assets(Edicy.layout_assets.map(&:id))
    end

    def create_assets(ids)
      ids.each do |id|
        la = Edicy.layout_asset id
        case la.asset_type
        when 'image'
          Dir.chdir('images')
        when 'stylesheet'
          Dir.chdir('stylesheets')
        when 'javascript'
          Dir.chdir('javascripts')
        else
          Dir.chdir('assets')
        end
        Net::HTTP.start(Edicy.site) do |http|
          resp = http.get(la.path)
          open(la.filename, "wb") do |file|
              file.write(resp.body)
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

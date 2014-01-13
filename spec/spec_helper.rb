require_relative '../lib/edicy/dtk.rb'
# require_relative '../bin/edicy'

require './lib/edicy/dtk/filemanager.rb'
# require_relative '../lib/edicy/dtk/guard.rb'
# require_relative '../lib/edicy/dtk/renderer.rb'

# require_relative '../lib/edicy/liquid/liquid.rb'
# require_relative '../lib/edicy/liquid/file_system.rb'

def get_layouts
    JSON.parse(File.read('../spec/fixtures/layouts.json')).map do |layout| 
      OpenStruct.new(layout.to_h)
    end  
end

def get_layout_assets
  JSON.parse(File.read('../spec/fixtures/layout_assets.json')).map do |asset| 
      OpenStruct.new(asset.to_h)
    end  
end

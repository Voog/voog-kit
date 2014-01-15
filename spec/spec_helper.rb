require_relative '../lib/edicy/dtk.rb'
require_relative '../lib/edicy/dtk/filemanager.rb'

RSpec.configure do |c|
  # filter_run is short-form alias for filter_run_including
  c.filter_run :focus => true
end

FIXTURE_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'fixtures'))

def get_layouts
  JSON.parse(File.read(FIXTURE_PATH + '/layouts.json')).map do |layout|
    OpenStruct.new(layout.to_h)
  end
end

def get_layout_assets
  JSON.parse(File.read(FIXTURE_PATH + '/layout_assets.json')).map do |asset|
    OpenStruct.new(asset.to_h)
  end
end

def get_layout_asset
  OpenStruct.new(JSON.parse(File.read(FIXTURE_PATH + '/layout_asset.json')).to_h)
end

def get_layout
  OpenStruct.new(JSON.parse(File.read(FIXTURE_PATH + '/layout.json')).to_h)
end

require 'edicy/liquid/liquid'

module Edicy::Dtk
  
  class Renderer
    
    attr_accessor :manifest
    
    def initialize(directory)
      
      @directory = directory
      
      if File.exists?(File.join(directory, 'manifest.json'))
        @manifest = JSON.parse(File.read(File.join(directory, 'manifest.json')))
  
        @file_system = Edicy::Liquid::FileSystem.new(directory, manifest)
        Liquid::Template.file_system = @file_system
      end
      
      if File.exists?(File.join(directory, 'site.json'))
        @data = JSON.parse(File.read(File.join(directory, 'site.json')))
      end
    end
    
    def render_all
      if File.exists?(File.join(@directory, 'site.json'))
        @data = JSON.parse(File.read(File.join(@directory, 'site.json')))
      end
      
      render_layout('layouts/front_page.tpl')
    end
    
    def render_layout(path)
      code = @file_system.read_layout(path)
      
      filename = path.split('/').last.split('.').first
      
      assigns = {
        'site' => {'header' => @data['site']['name']},
        'page' => {'title' => @data['site']['name']}
      }
      
      tpl = Liquid::Template.parse(code)
      File.open(File.join(@directory, "#{filename}.html"), 'w') do |file|
        file << tpl.render!(assigns, registers: {})
      end
    end
  end
end

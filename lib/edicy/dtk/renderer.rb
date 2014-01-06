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

    def render_pages
      if File.exists?(File.join(@directory, 'site.json'))
        @data = JSON.parse(File.read(File.join(@directory, 'site.json')))
      end
      sd = Edicy::Liquid::Drops::SiteDrop.new(@data)
      
      pages = []
      sd.root_item.children.map { |node| node.pages.map { |page| pages << page } } 
      sd.root_item.pages.map { |page| pages << page }

      pages.each { |page| render_page(page) }
    end

    def render_page(page)
      layout = @manifest["layouts"].select { |l| l["title"] == page.layout }.first
      code = @file_system.read_layout(layout["file"])
      filename = layout["file"].split('/').last.split('.').first

      sd = Edicy::Liquid::Drops::SiteDrop.new(@data)
      pd = Edicy::Liquid::Drops::PageDrop.new(page)
      language = sd.site.languages.select { |l| l.code == page.language }.first
      ld = Edicy::Liquid::Drops::LanguageDrop.new(language)

      assigns = { 
        "site" => sd.site, 
        "page" => pd,
        "language" => ld
      }

      assigns["articles"] = page.articles.map { |a| Edicy::Liquid::Drops::ArticleDrop.new(a) } if page.articles

      tpl = Liquid::Template.parse(code)

      File.open(File.join(@directory, "#{page.title}.html"), 'w') do |file|
        file << tpl.render!(assigns, registers: {})
      end

      puts "Rendered ./#{page.title}.html"
    end
  end
end

require 'edicy/liquid/liquid'

module Edicy::Dtk
  class Renderer
    attr_accessor :manifest, :editmode

    def initialize(directory)
      @directory = directory
      @editmode = false

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
      @manifest['layouts'].map { |layout| layout['file'] unless layout['component'] }.uniq.each do |layout|
        render_layout(layout) unless layout.nil?
      end
    end

    def render_pages(output_folder='html')
      if File.exists?(File.join(@directory, 'site.json'))
        @data = JSON.parse(File.read(File.join(@directory, 'site.json')))
      end
      sd = Edicy::Liquid::Drops::SiteDrop.new(@data)

      Dir.mkdir output_folder unless Dir.exists? output_folder

      sd.pages.each { |page| render_page(page, output_folder) }
    end

    def default_assigns
      {
        'editmode' => @editmode,
        'previewmode' => !@editmode,
        'javascripts_path' => 'javascripts',
        'images_path' => 'images',
        'photos_path' => 'photos',
        'stylesheets_path' => 'stylesheets',
        'assets_path' => 'assets'
      }
    end

    def render_page(page, output_folder='html')
      layout = @manifest['layouts'].select { |l| l['title'] == page.layout }.first
      return false unless layout
      code = @file_system.read_layout(layout['file'])

      sd = Edicy::Liquid::Drops::SiteDrop.new(@data, page)
      language = sd.site.languages.select { |l| l.code == page.language }.first
      pd = Edicy::Liquid::Drops::PageDrop.new(page)
      pd.site_title = sd.title
      ld = Edicy::Liquid::Drops::LanguageDrop.new(language)

      assigns = default_assigns.merge(
        'site' => sd,
        'page' => pd,
        'language' => ld
      )
      assigns['articles'] = page.articles.map { |a| Edicy::Liquid::Drops::ArticleDrop.new(a) } if page.articles

      tpl = Liquid::Template.parse(code)

      File.open(File.join(output_folder, "#{page.title}.html"), 'w') do |file|
        file << tpl.render!(assigns, registers: {})
      end
      puts "Rendered #{page.title}.html".white
    end
  end
end

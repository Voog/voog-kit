require 'edicy/liquid/liquid'

module Edicy::Dtk
  class Renderer
    attr_accessor :manifest, :editmode

    def initialize(directory, output_folder='html')
      @directory = directory
      @editmode = false
      @output_folder = output_folder

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
      Dir.mkdir @output_folder unless Dir.exists? @output_folder
      render_pages
      render_articles
    end

    def render_articles
      sd = Edicy::Liquid::Drops::SiteDrop.new(@data)
      blogs = sd.pages.select { |page| page.content_type == 'blog' }
      blogs.each do |blog|
        blog.articles.each do |article|
          render_article(blog, article)
        end
      end
    end

    def render_article(page, article)
      begin
        layout = @manifest['layouts'].select { |l| l['content_type'] == 'blog_article' }.first
        return false unless layout
        code = @file_system.read_layout(layout['file'])

        sd = Edicy::Liquid::Drops::SiteDrop.new(@data, page)
        language = sd.site.languages.select { |l| l.code == page.language }.first
        pd = Edicy::Liquid::Drops::PageDrop.new(page)
        pd.site_title = sd.title
        ld = Edicy::Liquid::Drops::LanguageDrop.new(language)
        ad = Edicy::Liquid::Drops::ArticleDrop.new(article)
        depth = pd.level + (@output_folder.split('/').length + 1)
        path_prefix = '../' * depth
        assigns = default_assigns.merge(
          'site' => sd,
          'page' => pd,
          'language' => ld,
          'depth' => depth,
          'article' => ad,
          'images_path' => path_prefix + 'images',
          'photos_path' => path_prefix + 'photos',
          'javascripts_path' => path_prefix + 'javascripts',
          'stylesheets_path' => path_prefix + 'stylesheets',
          'assets_path' => path_prefix + 'assets'
        )

        tpl = Liquid::Template.parse(code)
        article_folder = @output_folder + '/' + page.path
        Dir.mkdir article_folder unless Dir.exists? article_folder
        File.open("#{article_folder}/#{article.path}.html", 'w') do |file|
          file << tpl.render!(assigns, registers: {})
        end
        puts "Rendered #{article.path}.html".white
      rescue
        puts "Failed to render #{article.path}.html".red
      end
    end

    def render_pages
      if File.exists?(File.join(@directory, 'site.json'))
        @data = JSON.parse(File.read(File.join(@directory, 'site.json')))
      end
      sd = Edicy::Liquid::Drops::SiteDrop.new(@data)
      sd.pages.each { |page| render_page(page) }
    end

    def default_assigns
      {
        'editmode' => @editmode,
        'previewmode' => !@editmode
      }
    end

    def render_page(page)
      begin
        layout = @manifest['layouts'].select { |l| l['title'] == page.layout }.first
        return false unless layout
        code = @file_system.read_layout(layout['file'])

        sd = Edicy::Liquid::Drops::SiteDrop.new(@data, page)
        language = sd.site.languages.select { |l| l.code == page.language }.first
        pd = Edicy::Liquid::Drops::PageDrop.new(page)
        pd.site_title = sd.title
        ld = Edicy::Liquid::Drops::LanguageDrop.new(language)

        depth = pd.level + (@output_folder.split('/').length)
        path_prefix = '../' * depth
        assigns = default_assigns.merge(
          'site' => sd,
          'page' => pd,
          'language' => ld,
          'depth' => depth,
          'images_path' => path_prefix + 'images',
          'photos_path' => path_prefix + 'photos',
          'javascripts_path' => path_prefix + 'javascripts',
          'stylesheets_path' => path_prefix + 'stylesheets',
          'assets_path' => path_prefix + 'assets'
        )

        assigns['articles'] = page.articles.map do |a|
          a.parent_path = page.path
          Edicy::Liquid::Drops::ArticleDrop.new(a)
        end if page.articles

        tpl = Liquid::Template.parse(code)

        File.open(File.join(@output_folder, "#{page.title}.html"), 'w') do |file|
          file << tpl.render!(assigns, registers: {})
        end
        puts "Rendered #{page.title}.html".white
      rescue
        puts "Failed to render #{page.path}.html".red
      end
    end
  end
end

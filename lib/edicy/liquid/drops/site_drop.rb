require 'ostruct'

class NestedOpenStruct < OpenStruct
  def initialize(data = nil)
    @table = {}
    if data
      data.each do |k, v|
        # handle nested hashes
        if v.is_a? Hash
          @table[k.to_sym] = NestedOpenStruct.new(v)

        # handle nested hashes nested in arrays
        elsif v.is_a? Array
          if v.all? { |entry| entry.is_a? Hash }
            @table[k.to_sym] = v.map { |h| NestedOpenStruct.new(h) }
          end

        else
          @table[k.to_sym] = v
          new_ostruct_member(k)
        end
      end
    end
  end

  def [](key)
    @table[key]
  end
end

module Edicy::Liquid::Drops
  class SiteDrop < Liquid::Drop
    attr_reader :site
    def initialize(data, current_page = nil)
      @data = NestedOpenStruct.new(data: data).data.site
      @current_page = current_page
    end

    def cmssession?
      false
    end

    def languages
      site.languages.map { |l| LanguageDrop.new(l) }
    end

    def site
      @data
    end

    def menuitems
      root_item.children
    end

    def menuitems_with_hidden
      root_item.children_with_hidden
    end

    def all_menuitems
      root_item.all_children
    end

    def visible_menuitems
      root_item.children
    end

    def hidden_menuitems
      root_item.hidden_children
    end

    def root_item
      @root_item ||= begin
        mid = MenuItemDrop.new(PageDrop.new(@data.root), @current_page)
        mid.context = @context
        mid
      end
    end

    def author
      # site.meta_author
    end

    def keywords
      # site.meta_keywords
    end

    def copyright
      # site.meta_copyright
    end

    def name
      site.settings.site_name
    end

    def header
      site.languages.first.site_header
    end

    def title
      site.languages.first.site_title
    end

    def search
      { 'enabled' => site.search_enabled? }
    end

    def latest_articles(limit = 10)
      root_item.pages.select { |page|
        page.content_type == 'blog' && page.articles
      }.map { |page|
        page.articles.map { |article| ArticleDrop.new(article) }
      }.flatten.sort_by { |article| article.created_at }.slice(0, limit)
    end

    def pages
      root_item.pages
    end

    # Responds to dynamically named methods. Allows user to query the latest_n_articles on site.
    def before_method(method)
      if method.to_s.match(/^latest_(\d+)_articles$/)
        latest_articles($1.to_i)
      end
    end
  end
end

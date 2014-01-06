require 'ostruct'

class NestedOpenStruct < OpenStruct
  def initialize(data = nil)
    @table = {}
    if data
      for k, v in data
        # handle nested hashes
        if v.is_a? Hash
          @table[k.to_sym] = NestedOpenStruct.new(v)
          
        # handle nested hashes nested in arrays
        elsif v.is_a? Array
          if v.all? {|entry| entry.is_a? Hash }
            @table[k.to_sym] = v.map {|v| NestedOpenStruct.new(v) }
          end
          
        else
          @table[k.to_sym] = v
          new_ostruct_member(k)
        end
      end
    end
  end

  def [] (key)
    @table[key]
  end
end

module Edicy::Liquid::Drops

  class SiteDrop < Liquid::Drop
    
    def initialize(data)
      @data = NestedOpenStruct.new( :data => data ).data.site
      @data.title = @data.languages.first.site_title
      @data.header = @data.languages.first.site_header
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
      root_item.visible_children
    end
    
    def hidden_menuitems
      root_item.hidden_children
    end
    
    # Returns list of published language environments defined under site settings
    def languages
      @data.languages
    end
    
    def has_many_languages?
      not (languages.empty? or languages.size == 1)
    end

    def root_item
      @root_item ||= begin
        mid = MenuItemDrop.new(PageDrop.new(@data.root))
        mid.context = @context
        mid
      end
    end
    
    def rss_path
      relative_url_root + '/index.rss'
    end
    
    def author
      properties.meta_author
    end
    
    def keywords
      properties.meta_keywords
    end
    
    def copyright
      properties.meta_copyright
    end
    
    def name
      properties.site_name
    end
    
    # Returns site header. Loads it from language based site header and falls back to generic site header that is use
    # only by legacy cause.
    def header
      page.site_header || properties.site_header
    end
    
    def site_header
      properties.site_header
    end
    
    def analytics
      properties.stats_service_scripts.join("\n") unless cmssession?
    end
    
    def search
      {'enabled' => properties.search_enabled?}
    end
    
    def logo
      ""
    end
    
    def host
      host_with_port
    end
    
    def url
      "http://#{host}"
    end
    
    # def blogs
    #   if editing? # then show also hidden blogs
    #     @blogs ||= Page.blog.all(:conditions => {:language_id => page.language_id})
    #   else
    #     @blogs ||= Page.blog.all(:conditions => {:language_id => page.language_id, :hidden => false})
    #   end
    #   @blogs.select{ |p| show_unpublished_content? or p.published? }.collect{ |p| BlogDrop.new(p) }
    # end
    
    # def has_articles?
    #   @has_articles ||= begin
    #     (show_unpublished_content? ? Article.scoped : Article.published).first(
    #       :conditions => {:articles => {:language_id => page.language_id}, :pages => {:content_type => 'blog'}},
    #       :select => 'articles.id', :joins => :page
    #     ).present?
    #   end
    # end
    
    # def latest_articles(limit = 10)
    #   @latest_articles[limit] ||= begin
    #     (show_unpublished_content? ? Article.scoped : Article.published).descending.all(
    #       :conditions => {:articles => {:language_id => page.language_id}, :pages => {:content_type => 'blog'}},
    #       :include => [:author, {:page => :language}], :joins => :page, :limit => limit
    #     ).select{ |a| a.page.blog? }.collect{ |a| ArticleDrop.new(a) }
    #   end
    # end
    
    # def has_tags?
    #   @has_tags ||= Tag.first.present?
    # end
    
    # def all_tags
    #   @tags ||= Tag.all.collect{ |t| TagDrop.new(t) }
    # end
    
    # def has_language_tags?
    #   @has_language_tags ||= Tag.by_language(page.language_id).first.present?
    # end
    
    # def language_tags
    #   @language_tags ||= Tag.by_language(page.language_id).all.collect{ |t| TagDrop.new(t) }
    # end
    
    # def static_asset_host
    #   if defined? STATIC_ASSET_HOST then STATIC_ASSET_HOST else '' end
    # end
    
    # Responds to dynamically named methods. Allows user to query the latest_n_articles on site.
    def before_method(method)
      if method.to_s.match(/^latest_(\d+)_articles$/)
        latest_articles($1.to_i)
      end
    end
    
    private
    
    def siteroot
      @siteroot ||= Node.find_root
    end
    
    def properties
      @properties ||= SiteProperty.find_properties
    end
  end
end

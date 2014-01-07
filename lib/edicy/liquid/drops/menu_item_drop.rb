module Edicy::Liquid::Drops

  class MenuItemDrop < Liquid::Drop
    def initialize(page, current_page, node = nil)
      @page = page
      @current_page = current_page
    end
    
    def title
      @page.title
    end

    def path
      "#{@page.title}.html"
    end

    def url
      path
    end

    # Check if page is hidden
    def hidden?
      @page.hidden?
    end

    # Returns content type of the page associated with this item
    def content_type
      @page.content_type
    end
    
    # Returns true if page associated with this item is a blog
    def blog?
      @page.blog?
    end
    
    # Returns true if page or one of its children (or one of their childrens etc.) is currently shown.
    def selected?
      # TODO: Something more reliable
      @current_page.title == @page.title
    end
    
    # Returns true if current page is shown.
    def current?
      @current ||= @page.path == @current_page.path
    end
    
    # Returns list of MenuItemDrop objects which represents children of page this MenuItemDrop represents.
    def children
      @page.children.inject(Array.new) do |a, node|
        a << MenuItemDrop.new(PageDrop.new(node), @current_page)
        a
      end unless @page.children.nil?
    end

    def pages
      # TODO
    end

    # Returns list of MenuItemDrop objects which represents also hidden children of page this MenuItemDrop represents.
    def children_with_hidden
      children
    end

    # Returns list of MenuItemDrop objects which are representing all children (whether translated or untranslated) of
    # current MenuItemDrop
    def all_children
      children
    end
    
    # Returns true if menu item has child objects (only translated objects)
    def children?
      ! @page.children.nil?
    end
    
    # Returns true if menu item has child objects (both translated or untranslated)
    def all_children?
      ! all_children.empty?
    end
    
    # Returns true if this menu item is currently selected AND also has children
    def selected_with_children?
      children? and selected?
    end
    
    # Check if this menu item is already translated
    def translated?
      ! @page.new_record?
    end

  end

end

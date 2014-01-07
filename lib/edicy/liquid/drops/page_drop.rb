module Edicy::Liquid::Drops

  class PageDrop < Liquid::Drop
    
    def initialize(page)
      @page = page
    end

    def children
      @page.children
    end

    def pages
      @page.pages
    end
    
    def title
      @page.title
    end

    def content(key)
      @page.contents.select { |c| c.name == key }.first.text.body
    end

    def keywords
      @page.keywords
    end
    
    def description
      @page.description
    end
    
    def path
      @page.path
    end
    
    def path_with_lang
      @page.path
    end
    
    def created_at
      @page.created_at
    end
    
    def updated_at
      @page.updated_at
    end
    
    def hidden?
      @page.hidden
    end
    
    def language_code
      @page.language
    end
    
    def url
      '/' + @page.path
    end
    
    def blog?
      @page.content_type == 'blog'
    end
    
    def new_record?
      false
    end
  end

end

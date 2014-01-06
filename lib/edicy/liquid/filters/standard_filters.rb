module Edicy::Liquid::Filters
  module StandardFilters
  
    def format_date(input, format = :default)
      return input.to_s if format.to_s.empty?

      format = format.to_s if format.is_a? Symbol
      formats = {
        "default" =>"%d.%m.%Y",
        "short" =>"%b %d",
        "long" =>"%B %d, %Y"
      }
      format = formats.fetch(format, format)

      date = case input
      when String
        Date.parse(input)
      when Time
        input.to_date
      else
        input
      end
      
      if date.is_a?(Date)
        date.strftime(format)
      else
        input
      end
    rescue => e 
      input
    end
    
    def format_time(input, format = :default)
      return input.to_s if format.to_s.empty?

      format = format.to_s if format.is_a? Symbol
      formats = {
        "default" => "%a, %d %b %Y %H:%M",
        "short" => "%d %b %H:%M",
        "long" => "%B %d, %Y %H:%M"
      }
      format = formats.fetch(format, format)

      time = case input
      when String
        Time.parse(input)
      when Date
        input.to_time
      else
        input
      end
      
      if time.is_a?(Time)
        time.strftime(format)
      else
        input
      end
    rescue => e 
      input
    end

  end
end

Liquid::Template.register_filter(Edicy::Liquid::Filters::StandardFilters)

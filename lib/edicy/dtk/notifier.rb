require 'colorize'

module Edicy::Dtk
  class Notifier
    def initialize(output=$stderr, silent=false)
      @output = output
      @silent = silent
    end

    def normal(message)
      @output.print(message) unless @silent
    end

    def info(message)
      @output.print(message.white + ' ') unless @silent
    end

    def success(message)
      @output.print(message.green) unless @silent
    end

    def error(message)
      @output.print(message.red) unless @silent
    end

    def warning(message)
      @output.print(message.yellow) unless @silent
    end

    def newline
      @output.print("\n") unless @silent
    end
  end
end

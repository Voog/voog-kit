require 'edicy/dtk/version'
require 'parseconfig'

module Edicy
  module Dtk

    class << self
      def read_config(file = nil)
        config = {
          :host => nil,
          :api_token => nil,
          :editmode => false,
          :remote => false
        }
        if !file.nil? && !file.empty? && File.exists?(File.expand_path(file))
          options = ParseConfig.new(File.expand_path(file))
          config[:host] = options["OPTIONS"]["host"]
          config[:api_token] = options["OPTIONS"]["api_token"]
          config[:editmode] = options["OPTIONS"]["editmode"] == "true"
          config[:remote] = options["OPTIONS"]["remote"] == "true"
        end
        config
      end
    end
  end
end

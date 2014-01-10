require 'edicy/dtk/version'
require 'parseconfig'

module Edicy
  module Dtk

    class << self
      def read_config(file = nil)
        config = {
          :site_url => nil,
          :api_token => nil
        }
        if !file.nil? && !file.empty? && File.exists?(File.expand_path(file))
          options = ParseConfig.new(File.expand_path(file))
          config[:site_url] = options["OPTIONS"]["url"]
          config[:api_token] = options["OPTIONS"]["api_token"]
        end
        config
      end
    end
  end
end

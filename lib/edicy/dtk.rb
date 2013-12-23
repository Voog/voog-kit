require 'edicy/dtk/version'
require 'parseconfig'

module Edicy
  module Dtk

    class << self
      def read_config
        config = {
          :site_url => nil,
          :api_token => nil
        }
        if File.exists?(File.expand_path(CONFIG))
          options = ParseConfig.new(File.expand_path(CONFIG))
          config[:site_url] = options["OPTIONS"]["url"]
          config[:api_token] = options["OPTIONS"]["api_token"]
        end
        config
      end
    end
  end
end

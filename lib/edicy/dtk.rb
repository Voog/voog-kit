require 'edicy/dtk/version'
require 'parseconfig'

module Edicy
  module Dtk

    class << self
      def read_config(file = nil)
        config = {
          :host => nil,
          :api_token => nil
        }
        if !file.nil? && !file.empty? && File.exists?(File.expand_path(file))
          options = ParseConfig.new(File.expand_path(file))
          config[:host] = options["OPTIONS"].fetch("host")
          config[:api_token] = options["OPTIONS"].fetch("api_token")

          if options["OPTIONS"].fetch("editmode", false)
            config[:editmode] = options["OPTIONS"].fetch("editmode") == "true"
          end

          if options["OPTIONS"].fetch("remote", false)
            config[:remote] = options["OPTIONS"].fetch("remote") == "true"
          end
        end
        config
      end

      def write_config(host, api_token, silent=false)
        options = File.exists?('.edicy') ? self.read_config('.edicy') : nil

        File.delete '.edicy' if File.exists? '.edicy'

        if options
          puts "Writing new configuration options to existing .edicy file.".white unless silent
          options = options.merge(host: host, api_token: api_token)
        else
          puts "Writing configuration options to missing .edicy file.".white unless silent
          options = { host: host, api_token: api_token }
        end

        File.open('.edicy', 'w') do |file|
          file.write("[OPTIONS]\n")
          options.each do |key,value|
            file.write("  #{key}=#{value}\n")
          end
        end
      end
    end
  end
end

require 'voog/dtk/version'
require 'parseconfig'

module Voog
  module Dtk

    CONFIG_FILENAME = '.voog'

    class << self
      def config_exists?
        File.exists? CONFIG_FILENAME
      end

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
        options = File.exists?(CONFIG_FILENAME) ? self.read_config(CONFIG_FILENAME) : nil

        File.delete CONFIG_FILENAME if File.exists? CONFIG_FILENAME

        if options
          puts "Writing new configuration options to existing #{CONFIG_FILENAME} file.".white unless silent
          options[:host] = host unless host.empty?
          options[:api_token] = api_token unless api_token.empty?
        else
          puts "Writing configuration options to missing #{CONFIG_FILENAME} file.".white unless silent
          options = { host: host, api_token: api_token }
        end

        File.open(CONFIG_FILENAME, 'w') do |file|
          file.write("[OPTIONS]\n")
          options.each do |key,value|
            file.write("  #{key}=#{value}\n")
          end
        end
      end

      def handle_exception(exception, notifier=nil)
        error_msg = if [
          Faraday::ClientError,
          Faraday::ConnectionFailed,
          Faraday::ParsingError,
          Faraday::TimeoutError,
          Faraday::ResourceNotFound
        ].include? exception.class
          if exception.respond_to?(:response) && exception.response.fetch(:headers, {}).fetch(:content_type, '') =~ /application\/json/
            body = JSON.parse(exception.response.fetch(:body))
            "#{body.fetch('message', '')} #{("Errors: " + body.fetch('errors', '').inspect) if body.fetch('errors', nil)}".red
          else
            exception.response.fetch(:body)
          end + "(error code #{exception.response[:status]})".red
        else
          "#{exception}"
        end

        if notifier
          notifier.newline
          notifier.error error_msg
          notifier.newline
        else
          puts error_msg
        end
      end
    end
  end
end

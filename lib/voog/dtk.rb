require 'voog/dtk/version'
require 'parseconfig'
require 'prettyprint'

module Voog
  module Dtk

    CONFIG_FILENAME = '.voog'

    class << self
      def config_exists?
        File.exists? CONFIG_FILENAME
      end

      def read_config(block = nil, file = CONFIG_FILENAME)
        config = {
          :host => nil,
          :api_token => nil
        }
        if !file.nil? && !file.empty? && File.exists?(File.expand_path(file))
          options = ParseConfig.new(File.expand_path(file))
          @block = if block.nil?
            options.params.keys.first
          else
            if options.params.key?(block)
              block
            else
              fail "Site '#{block}' not found in the configuration file!".red
            end
          end
          config[:host] = options.params[@block].fetch("host")
          config[:api_token] = options.params[@block].fetch("api_token")
        end
        config
      end

      def write_config(host, api_token, block, silent=false)
        unless File.exists?(CONFIG_FILENAME)
          File.new(CONFIG_FILENAME, 'w')
        end

        options = ParseConfig.new(File.expand_path(CONFIG_FILENAME))

        if options.params.key?(block)
          puts "Writing new configuration options to existing config block.".white unless silent
          options.params[block]['host'] = host unless host.empty?
          options.params[block]['api_token'] = api_token unless api_token.empty?
        else
          puts "Writing configuration options to new config block.".white unless silent
          options.params[block] = {
            'host' => host,
            'api_token' => api_token
          }
        end

        File.open(CONFIG_FILENAME, 'w') do |file|
          file.truncate(0)
          file << "\n"
          options.params.each do |param|
            file << "[#{param[0]}]\n"
            param[1].keys.each do |key|
              file << "  #{key}=#{param[1][key]}\n"
            end
            file << "\n"
          end
        end
      end

      def is_api_error?(exception)
        [
          Faraday::ClientError,
          Faraday::ConnectionFailed,
          Faraday::ParsingError,
          Faraday::TimeoutError,
          Faraday::ResourceNotFound
        ].include? exception.class
      end

      def print_debug_info(exception)
        puts
        puts "Exception: #{exception.class}"
        if is_api_error?(exception) && exception.respond_to?(:response) && exception.response
          pp exception.response
        end
        puts exception.backtrace
      end

      def handle_exception(exception, debug, notifier=nil)
        error_msg = if is_api_error?(exception)
          if exception.respond_to?(:response) && exception.response
            if exception.response.fetch(:headers, {}).fetch(:content_type, '') =~ /application\/json/
              body = JSON.parse(exception.response.fetch(:body))
              "#{body.fetch('message', '')} #{("Errors: " + body.fetch('errors', '').inspect) if body.fetch('errors', nil)}".red
            else
              exception.response.fetch(:body)
            end + "(error code #{exception.response[:status]})".red
          else
            "#{exception}"
          end
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
        print_debug_info(exception) if debug
      rescue => e
        handle_exception e, debug, notifier
      end
    end
  end
end

module Edicy
  module Liquid
    class FileSystem
      def initialize(folder, manifest)
        @folder = folder
        @manifest = manifest
      end

      def read_template_file(template)
        template_file_name = @manifest['layouts'].find { |l| l['title'] == template }
        if !template_file_name.nil?
          File.read(File.join(@folder, template_file_name.fetch('file')))
        else
          fail "ERROR: Invalid template name '#{template}'"
        end
      end

      def read_layout(path)
        File.read(File.expand_path(File.join(@folder, path)))
      end
    end
  end
end

module Edicy
  module Liquid
    
    class FileSystem
      
      def initialize(folder, manifest)
        @folder = folder
        @manifest = manifest
      end
      
      def read_template_file(template)
        template_file_name = @manifest['layouts'].find{ |l| l['title'] == template }.fetch('file')
        File.read(File.join(@folder, template_file_name))
      end
      
      def read_layout(path)
        File.read(File.expand_path(File.join(@folder, path)))
      end
    end
  end
end

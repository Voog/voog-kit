require 'listen'
# module Guard
#   class VoogKit < Plugin
#     attr_accessor :options, :filemanager, :debug

#     def initialize(options = {})
#       @options = options
#       super(options)
#     end

#     def run_on_additions(paths)
#       @filemanager.add_files paths
#     rescue => e
#       @filemanager.notifier.newline
#       Voog::Dtk.handle_exception e, @debug, @filemanager.notifier
#     end

#     def run_on_removals(paths)
#       @filemanager.remove_files paths
#     rescue => e
#       @filemanager.notifier.newline
#       Voog::Dtk.handle_exception e, @debug, @filemanager.notifier
#     end

#     def run_on_modifications(paths)
#       @filemanager.upload_files paths
#       @filemanager.notifier.newline
#     rescue => e
#       @filemanager.notifier.newline
#       Voog::Dtk.handle_exception e, @debug, @filemanager.notifier
#     end
#   end
# end

module Voog::Dtk
  class Watcher
    def initialize(filemanager, debug=false)
      paths = ['layouts/', 'components/', 'assets/', 'javascripts/', 'stylesheets/', 'images/']

      @filemanager = filemanager
      @debug = debug
      @listener = Listen.to(*paths) do |modified, added, removed|
        handle_added added unless added.empty?
        handle_removed removed unless removed.empty?
        handle_modified modified unless modified.empty?
      end
    end

    def handle_added(added)
      @filemanager.add_files added
    rescue => e
      @filemanager.notifier.newline
      Voog::Dtk.handle_exception e, @debug, @filemanager.notifier
    end

    def handle_removed(removed)
      @filemanager.remove_files removed
    rescue => e
      @filemanager.notifier.newline
      Voog::Dtk.handle_exception e, @debug, @filemanager.notifier
    end

    def handle_modified(modified)
      @filemanager.upload_files modified
    rescue => e
      @filemanager.notifier.newline
      Voog::Dtk.handle_exception e, @debug, @filemanager.notifier
    end

    def run
      @listener.start
      sleep
    end
  end
end

require 'guard'
require 'guard/guard'
require 'guard/plugin'

module Guard
  class Shell < Guard
    VERSION = '0.5.2'

    # Calls #run_all if the :all_on_start option is present.
    def start
      run_all if options[:all_on_start]
    end

    # Call #run_on_change for all files which match this guard.
    def run_all
      run_on_modifications(Watcher.match_files(self, Dir.glob('{,**/}*{,.*}').uniq))
    end

    # Print the result of the command(s), if there are results to be printed.
    def run_on_modifications(res)
      puts res if res
    end
  end
end

module Voog::Dtk
  class ::Guard::Watchman < ::Guard::Plugin
    attr_accessor :options, :filemanager

    # Initializes a Guard plugin.
    # Don't do any work here, especially as Guard plugins get initialized even if they are not in an active group!
    #
    # @param [Hash] options the custom Guard plugin options
    # @option options [Array<Guard::Watcher>] watchers the Guard plugin file watchers
    # @option options [Symbol] group the group this Guard plugin belongs to
    # @option options [Boolean] any_return allow any object to be returned from a watcher
    #
    def initialize(options = {})
      super
      @options = options
    end

    # Called once when Guard starts. Please override initialize method to init stuff.
    #
    # @raise [:task_has_failed] when start has failed
    # @return [Object] the task result
    #
    def start
      ::Guard::UI.info 'Guard::Voog is running'
      # run_all
    end

    # Called when `stop|quit|exit|s|q|e + enter` is pressed (when Guard quits).
    #
    # @raise [:task_has_failed] when stop has failed
    # @return [Object] the task result
    #
    def stop
      ::Guard::UI.info 'Guard::Voog stopped'
    end

    # Called when `reload|r|z + enter` is pressed.
    # This method should be mainly used for "reload" (really!) actions like reloading passenger/spork/bundler/...
    #
    # @raise [:task_has_failed] when reload has failed
    # @return [Object] the task result
    #
    # def reload
    # end

    # Called when just `enter` is pressed
    # This method should be principally used for long action like running all specs/tests/...
    #
    # @raise [:task_has_failed] when run_all has failed
    # @return [Object] the task result
    #
    def run_all
    end

    # Default behaviour on file(s) changes that the Guard plugin watches.
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_change has failed
    # @return [Object] the task result
    #
    # def run_on_changes(paths)
    # end

    # Called on file(s) additions that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_additions has failed
    # @return [Object] the task result
    #
    def run_on_additions(paths)
      @filemanager.add_to_manifest paths
      @filemanager.upload_files paths
    rescue => e
      @filemanager.notifier.newline
      Voog::Dtk.handle_exception e, @filemanager.notifier
    end

    # Called on file(s) removals that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_removals has failed
    # @return [Object] the task result
    #
    def run_on_removals(paths)
      @filemanager.remove_from_manifest paths
    rescue => e
      @filemanager.notifier.newline
      Voog::Dtk.handle_exception e, @filemanager.notifier
    end

    # Called on file(s) modifications that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_modifications has failed
    # @return [Object] the task result
    #
    def run_on_modifications(paths)
      @filemanager.upload_files paths
      @filemanager.notifier.newline
    rescue => e
      @filemanager.notifier.newline
      Voog::Dtk.handle_exception e, @filemanager.notifier
    end
  end

  class Guuard
    def initialize(filemanager)
      @filemanager = filemanager
    end

    def run
      guardfile = <<-EOF
        guard 'watchman' do
          watch(%r{^(layout|component|image|asset|javascript|stylesheet)s/.*})
        end
      EOF

      ::Guard.start(guardfile_contents: guardfile)
      ::Guard.guards('watchman').first.filemanager = @filemanager
    end
  end
end

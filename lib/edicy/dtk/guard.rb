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

module Edicy::Dtk
  
  class Runner
    def initialize(options = {})
      
    end
    
    def run_all
      puts 'Runner run all'
    end
    
    def run(paths)
      puts 'Runner run'
      puts paths.inspect
    end
  end
  
  class ::Guard::Yoyo < ::Guard::Plugin
    
    attr_accessor :options, :runner, :renderer
    
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
      @runner = Runner.new(@options)
    end

    # Called once when Guard starts. Please override initialize method to init stuff.
    #
    # @raise [:task_has_failed] when start has failed
    # @return [Object] the task result
    #
    def start
      # puts 'YOYO start'
      ::Guard::UI.info 'Guard::Edicy is running'
      # run_all
    end

    # Called when `stop|quit|exit|s|q|e + enter` is pressed (when Guard quits).
    #
    # @raise [:task_has_failed] when stop has failed
    # @return [Object] the task result
    #
    def stop
      ::Guard::UI.info 'Guard::Edicy stopped'
    end

    # Called when `reload|r|z + enter` is pressed.
    # This method should be mainly used for "reload" (really!) actions like reloading passenger/spork/bundler/...
    #
    # @raise [:task_has_failed] when reload has failed
    # @return [Object] the task result
    #
    # def reload
    #   puts 'YOYO reload'
    # end

    # Called when just `enter` is pressed
    # This method should be principally used for long action like running all specs/tests/...
    #
    # @raise [:task_has_failed] when run_all has failed
    # @return [Object] the task result
    #
    def run_all
      ::Guard::UI.info 'Guard::Edicy re-render all'
      # runner.run_all
      renderer.render_all
    end

    # Default behaviour on file(s) changes that the Guard plugin watches.
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_change has failed
    # @return [Object] the task result
    #
    # def run_on_changes(paths)
    #   puts paths
    #   puts 'YOYO run on changes'
    # end

    # Called on file(s) additions that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_additions has failed
    # @return [Object] the task result
    #
    # def run_on_additions(paths)
    #   puts 'YOYO run on additions'
    # end

    # Called on file(s) modifications that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_modifications has failed
    # @return [Object] the task result
    #
    def run_on_modifications(paths)
      ::Guard::UI.info 'Guard::Edicy render'
      
      paths.each do |path|
        if path =~ /^layouts/
          ::Guard::UI.info "Render #{path}"
          renderer.render_layout(path)
        elsif path == 'site.json'
          ::Guard::UI.info "site.json has changed, rendering all layouts"
          renderer.render_all
        end
      end
    end

    # Called on file(s) removals that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_removals has failed
    # @return [Object] the task result
    #
    # def run_on_removals(paths)
    #   puts 'YOYO run on removals'
    # end
  end
  
  class Guuard
    
    def initialize(renderer)
      @renderer = renderer
    end
    
    def run
      
      guardfile = <<-EOF
        guard 'yoyo', myoption: 'blah' do
          watch(%r{^layouts/.*})
          watch('site.json')
        end
      EOF
      
      # You can omit the call to Guard.setup, Guard.start will call Guard.setup
      # under the hood if Guard has not been setuped yet
      ::Guard.start(guardfile_contents: guardfile)
      # ::Guard.start(guardfile_contents: guardfile)
      ::Guard.guards('yoyo').first.renderer = @renderer
    end
  end
end

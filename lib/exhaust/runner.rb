module Exhaust
  class Runner

    attr_reader :configuration
    def initialize(configuration=Exhaust::Configuration.new)
      @configuration = configuration
    end

    def run
      Timeout::timeout(120) do

        puts "*** Emberjs app"
        puts "--> Starting..."
        while running = ember_server.gets
          if running =~ /build successful/i
            break
          end
        end
        puts "--> Started!"

        puts "*** Rails app"
        puts "--> Starting..."
        while running = rails_server.gets
          if running =~ /Use Ctrl-C to stop/i
            break
          end
        end
        puts "--> Started!"
      end
    end

    def ember_host
      "http://localhost:#{ember_port}"
    end

    def ember_port
      configuration.ember_port.to_s
    end

    def rails_port
      configuration.rails_port.to_s
    end

    def ember_path
      configuration.ember_path
    end

    def rails_path
      configuration.rails_path
    end

    def ember_server
      @ember_server ||= begin
        Dir.chdir(ember_path) do
          @ember_server = IO.popen([{"API_HOST" => "http://localhost:#{rails_port}"}, "npx", "ember", "server", "--port", ember_port, "--live-reload", "false", :err => [:child, :out]])
        end
      end
    end

    def rails_server
      @rails_server ||= begin
        Dir.chdir(rails_path) do
          @rails_server = IO.popen(['bundle', 'exec', 'rails', 'server', '--port', rails_port, '--environment', 'test', :err => [:child, :out]])
        end
      end
    end

    def shutdown!
      puts "*** Shutting down: ember (#{ember_server.pid}), rails (#{rails_server.pid})"
      Process.kill(9, ember_server.pid, rails_server.pid)
    end
  end
end

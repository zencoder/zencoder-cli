module Zencoder::CLI
  module Command
    extend Zencoder::CLI::Helpers

    class UnknownCommandName < RuntimeError; end

    mattr_accessor :commands
    self.commands = {}

    class << self

      def run(command, args, global_options={}, command_options={})
        Zencoder::CLI::Auth.require_authentication(global_options[:environment]) unless command[/^setup/]
        pieces = command.split(":")
        if pieces.size == 1
          method_name = :run
          klass_name = pieces.first.camelize
        else
          method_name = pieces.pop
          klass_name = pieces.map(&:camelize).join("::")
        end
        klass = "Zencoder::CLI::Command::#{klass_name}".constantize
        if klass.respond_to?(method_name)
          klass.send(method_name, args, global_options, command_options)
        else
          raise UnknownCommandName
        end
      rescue UnknownCommandName, NameError => e
        if e.class == UnknownCommandName || e.message[/uninitialized constant Zencoder::CLI::Command::/]
          error "There is no command named #{command}. Use --help for more information."
        else
          raise e
        end
      end

    end
  end
end

require 'zencoder-cli/commands/base'
Dir["#{File.dirname(__FILE__)}/commands/*.rb"].each { |c| require c }

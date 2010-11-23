module Zencoder::CLI::Command
  class Base
    extend Zencoder::CLI::Helpers

    class << self

      def provides(name, commands={})
        Zencoder::CLI::Command.commands.merge!({ name => commands })
      end

      def extract_id(args)
        arg = args.shift
        if arg.to_s.strip[/^\d+$/]
          arg
        else
          print "Enter an ID: "
          id = ask
          if id.present?
            id
          else
            puts "No ID given. Aborting."
            exit 1
          end
        end
      end

    end
  end
end

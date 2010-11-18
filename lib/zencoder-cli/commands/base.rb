module Zencoder::CLI::Command
  class Base
    extend Zencoder::CLI::Helpers

    class << self

      def provides(name, commands={})
        Zencoder::CLI::Command.commands.merge!({ name => commands })
      end

    end
  end
end

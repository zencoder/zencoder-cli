Zencoder::CLI::Plugin.load!

head = "#{"-" * (14 + Zencoder::CLI::GEM_VERSION.length)}
Zencoder CLI v#{Zencoder::CLI::GEM_VERSION}
#{"-" * (14 + Zencoder::CLI::GEM_VERSION.length)}"

global_options = Trollop::options do
  version "Zencoder #{Zencoder::CLI::GEM_VERSION}"
  banner <<-EOS
#{head}

== Usage

zencoder [global-options] command [command-options]

== Available Commands

#{
  Zencoder::CLI::Command.commands.sort.map{|group, commands|
    commands.map{|command, description|
      command.ljust(22)+" # "+(description.is_a?(String) ? description : description[:description])
    }.join("\n")
  }.join("\n\n")
}

== Global Options
EOS
  opt :environment, "Sets the environment to use (optional: defaults to production)", :type => String
  stop_on Zencoder::CLI::Command.commands.map{|k, v| v.keys }.flatten
end

if ARGV.empty?
  puts "You must specify a command. Use --help for more information."
  exit(1)
end

command = ARGV.shift.strip
args = ARGV


flat_commands = Zencoder::CLI::Command.commands.values.inject({}){|memo,group| memo.merge!(group) }
command_options = Trollop::options do
  banner <<-EOS
#{head}
#{
  if flat_commands[command] && flat_commands[command][:help]
    "\n"+flat_commands[command][:help]+"\n"
  end
}
== Usage

zencoder [global-options] #{command}#{" [args]" if flat_commands[command] && flat_commands[command][:arguments]} [options]
#{
  if flat_commands[command] && flat_commands[command][:arguments]
    "\n== Arguments\n\n"+
    (1..flat_commands[command][:arguments].size).to_a.map{|i|
      "#{i}: #{flat_commands[command][:arguments][i-1].to_s}"
    }.join("\n")
  end
}

== Command Options
EOS
  if flat_commands[command] && flat_commands[command][:options]
    flat_commands[command][:options].call(self)
  end
end


Zencoder::CLI::Command.run(command, args, global_options, command_options)

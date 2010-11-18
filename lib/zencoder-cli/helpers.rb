# Thank you Heroku gem.

module Zencoder::CLI
  module Helpers

    def home_directory
      running_on_windows? ? ENV['USERPROFILE'] : ENV['HOME']
    end

    def running_on_windows?
      RUBY_PLATFORM =~ /mswin32|mingw32/
    end

    def running_on_a_mac?
      RUBY_PLATFORM =~ /-darwin\d/
    end

    def format_date(date)
      date = Time.parse(date) if date.is_a?(String)
      date.strftime("%Y-%m-%d %H:%M %Z")
    end

    def display(msg, newline=true)
      if newline
        puts(msg)
      else
        print(msg)
        STDOUT.flush
      end
    end

    def error(msg)
      STDERR.puts(msg)
      exit 1
    end

    def confirm(message="Are you sure you wish to continue? (y/N)?")
      display("#{message} ", false)
      ask.downcase == 'y'
    end

    def ask
      gets.strip
    rescue Interrupt
      puts
      exit
    end

    def truncate(text, *args)
      options = args.extract_options!
      options.reverse_merge!(:length => 30, :omission => "...")

      if text
        l = options[:length] - options[:omission].mb_chars.length
        chars = text.mb_chars
        (chars.length > options[:length] ? chars[0...l] + options[:omission] : text).to_s
      end
    end

  end
end

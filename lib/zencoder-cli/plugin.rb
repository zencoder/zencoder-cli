# based on the Rails Plugin

module Zencoder::CLI
  class Plugin
    extend Zencoder::CLI::Helpers

    attr_reader :name, :uri

    def self.directory
      File.expand_path("#{home_directory}/.zencoder/plugins")
    end

    def self.list
      Dir["#{directory}/*"].sort.map do |folder|
        File.basename(folder)
      end
    end

    def self.load!
      list.each do |plugin|
        begin
          load_plugin(plugin)
        rescue Exception => e
          display "Unable to load plugin: #{plugin}: #{e.message}"
        end
      end
    end

    def self.load_plugin(plugin)
      folder = "#{self.directory}/#{plugin}"
      $: << "#{folder}/lib"    if File.directory? "#{folder}/lib"
      load "#{folder}/init.rb" if File.exists?  "#{folder}/init.rb"
    end

    def initialize(uri)
      @uri = uri
      guess_name(uri)
    end

    def to_s
      name
    end

    def path
      "#{self.class.directory}/#{name}"
    end

    def install
      FileUtils.mkdir_p(path)
      Dir.chdir(path) do
        system("git init -q")
        if !system("git pull #{uri} -q")
          FileUtils.rm_rf path
          return false
        end
      end
      true
    end

    def uninstall
      FileUtils.rm_r path if File.directory?(path)
    end


  private

    def guess_name(url)
      @name = File.basename(url)
      @name = File.basename(File.dirname(url)) if @name.empty?
      @name.gsub!(/\.git$/, '') if @name =~ /\.git$/
    end

  end
end

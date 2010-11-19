# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'zencoder-cli/version'

Gem::Specification.new do |s|
  s.name        = "zencoder-cli"
  s.version     = Zencoder::CLI::GEM_VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = "Brandon Arbini"
  s.email       = "info@zencoder.com"
  s.homepage    = "http://github.com/zencoder/zencoder-cli"
  s.summary     = "Zencoder <http://zencoder.com> CLI client."
  s.description = "Zencoder <http://zencoder.com> CLI client."
  s.rubyforge_project = "zencoder-cli"
  s.add_dependency "zencoder", "~>2.3.1"
  s.add_dependency "trollop", "~>1.16.2"
  s.add_dependency "terminal-table", "~>1.4.2"
  s.files        = Dir.glob("bin/**/*") + Dir.glob("lib/**/*") + %w(LICENSE README.markdown)
  s.executables << "zencoder"
  s.require_path = "lib"
end

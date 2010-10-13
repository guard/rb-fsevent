# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rb-fsevent/version"

Gem::Specification.new do |s|
  s.name        = "rb-fsevent"
  s.version     = RbFSEvent::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Thibaud Guillaume-Gentil']
  s.email       = ['thibaud@thibaud.me']
  s.homepage    = "http://rubygems.org/gems/rb-fsevent"
  s.summary     = "Very simple & usable FSEvents API"
  s.description = "FSEvents API using FFI and without RubyCocoa dependency"
  
  s.rubyforge_project = "rb-fsevent"
  
  s.add_dependency 'ffi',   '~> 0.6.3'
  
  s.files        = Dir.glob('{bin,lib}/**/*') + %w[LICENSE README.rdoc]
  s.require_path = 'lib'
end

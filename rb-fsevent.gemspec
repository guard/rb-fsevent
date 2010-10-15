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
  s.description = "FSEvents API using FFI (without RubyCocoa)"
  
  s.rubyforge_project = "rb-fsevent"
  
  s.add_dependency 'ffi',   '~> 0.6.3'
  
  s.add_development_dependency  'bundler',     '~> 1.0.2'
  s.add_development_dependency  'rspec',       '~> 2.0.0'
  s.add_development_dependency  'guard-rspec', '~> 0.1.3'
  
  s.files        = Dir.glob('{bin,lib}/**/*') + %w[LICENSE README.rdoc]
  s.require_path = 'lib'
end

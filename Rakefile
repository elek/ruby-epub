# -*- ruby -*-

require 'rubygems'
Gem::manage_gems

require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/testtask'

spec = Gem::Specification.new do |s|
    s.name              = 'ruby-epub'
    s.version           = '0.0.1'
    s.author            = 'Arachne Jericho'
    s.email             = 'arachne.jericho@gmail.com'
    s.homepage          = 'https://ruby-epub.googlecode.com/'
    s.platform          = Gem::Platform::RUBY
    s.summary           = 'An EPUB (and associated file formats, like OPF) library for Ruby.'
    s.files             = FileList['{bin,docs,lib,test}/**/*'].exclude('rdoc').to_a

    s.require_path      = 'lib'
    s.autorequire       = 'epub'
    # s.test_file       = 'test/test-epub.rb'
    s.has_rdoc          = true
    s.extra_rdoc_files  = ['README']
    # s.add_dependency()
end


Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
end

Rake::TestTask.new do |t| 
    t.libs << "test"
    t.test_files = FileList['test/test*.rb']
    t.verbose = true
end

CLEAN.include('pkg')

task :default => [ :clean, :package, :test ]

# vim: syntax=Ruby

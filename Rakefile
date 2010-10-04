# -*- ruby -*-

require 'rubygems'

require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/testtask'

# Set up the umask properly. 
File.umask(0022)

spec = Gem::Specification.new do |s|
    s.name              = 'ruby-epub'
    s.version           = '0.0.6'
    s.author            = 'Arachne Jericho, modified by Elek Marton'
    s.email             = 'arachne.jericho@gmail.com, einstand@gmail.com'
    s.homepage          = 'https://ruby-epub.googlecode.com/'
    s.platform          = Gem::Platform::RUBY
    s.summary           = 'An EPUB (and associated file formats, like OPF) library for Ruby.'
    s.files             = FileList['History', 'TODO', 'LICENSE', '{bin,docs,lib,test,html}/**/*'].exclude('rdoc').to_a
    s.executables       = ['epub']
    s.require_path      = 'lib'
    # s.test_file       = 'test/test-epub.rb'
    s.has_rdoc          = true
    s.extra_rdoc_files  = ['README']
end


Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
    pkg.need_zip = true
end

Rake::TestTask.new do |t| 
    t.libs << "test"
    t.test_files = FileList['test/test*.rb']
    t.verbose = true
end

CLEAN.include('pkg')

require 'rake/rdoctask'
Rake::RDocTask.new do |rd|
    rd.main = "README"
    rd.rdoc_files.include("README", "lib/**/*.rb")
end

task :default => [ :rdoc, :package]
task :clean => :clobber_rdoc

# vim: syntax=Ruby

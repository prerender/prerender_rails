#!/usr/bin/env rake
require "bundler/gem_tasks"
 
require 'rake/testtask'
 
Rake::TestTask.new do |t|
  t.libs << 'lib/prerender_rails'
  t.test_files = FileList['test/lib/prerender_rails.rb']
  t.verbose = true
end
 
task :default => :test

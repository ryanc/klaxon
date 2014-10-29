$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

require 'rake/testtask'

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
end

task :default => :test

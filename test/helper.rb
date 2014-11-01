$LOAD_PATH.unshift(File.expand_path('../', File.dirname(__FILE__)))

require 'minitest/autorun'
require 'rack/test'
require 'vcr'
require 'app'

VCR.configure do |c|
  c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  c.hook_into :webmock
end

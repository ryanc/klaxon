$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

require 'twilio-ruby'
require 'app'
require 'sass/plugin/rack'

use Rack::TwilioWebhookAuthentication, ENV['TWILIO_AUTH_TOKEN'], '/call', '/sms'
use Sass::Plugin::Rack

Sass::Plugin.options[:style] = :compressed

app = Rack::Builder.new do
  map "/call" do
    run CallHandler.new
  end
  map "/sms" do
    run SMSHandler.new
  end
  map "/" do
    run WebHandler.new
  end
end

run app

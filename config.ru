$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

require 'twilio-ruby'
require 'app'

use Rack::TwilioWebhookAuthentication, ENV['TWILIO_AUTH_TOKEN'], '/'

app = Rack::Builder.new do
  map "/call" do
    run CallHandler.new
  end
  map "/sms" do
    run SMSHandler.new
  end
end

run app

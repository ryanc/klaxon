$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

require 'app'

app = Rack::Builder.new do
  map "/call" do
    run CallHandler.new
  end
  map "/sms" do
    run SMSHandler.new
  end
end

run app

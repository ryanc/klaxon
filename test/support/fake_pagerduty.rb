require 'sinatra/base'

class FakePagerDuty < Sinatra::Base
  post '/generic/2010-04-15/create_event.json' do
    json_response 200, 'trigger.json'
  end

  private

  def json_response(response_code, file_name)
    content_type :json
    status response_code
    File.open(File.dirname(__FILE__) + '/fixtures/' + file_name, 'rb').read
  end

  # Start the server if ruby file is executed directly.
  run! if app_file == $0
end

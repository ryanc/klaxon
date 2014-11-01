require 'helper'
require 'webmock/minitest'

class TestCallHandler < Minitest::Test
  include Rack::Test::Methods

  def setup
    @sample_recording_url = 'http://api.twilio.com/2010-04-01/Accounts/AC00000000000000000000000000000000/Recordings/RE00000000000000000000000000000000'
  end

  def app
    CallHandler
  end

  def test_greeting
    post '/greeting', { 'Caller' => '+15555555555', 'RecordingUrl' => @sample_recording_url }
    assert_includes(last_response.headers['Content-Type'], 'text/xml')
    assert_equal(200, last_response.status)
    assert_equal(
      %q(<?xml version="1.0" encoding="UTF-8"?><Response><Say>Please leave a message for the on call technician.</Say><Pause/><Record action="/call/voicemail"/></Response>),
      last_response.body
    )
  end

  def test_voicemail
    VCR.use_cassette('create_event_voicemail') do
      post '/voicemail', { 'Caller' => '+15555555555', 'RecordingUrl' => @sample_recording_url }
    end

    assert_includes(last_response.headers['Content-Type'], 'text/xml')
    assert_equal(
      %q(<?xml version="1.0" encoding="UTF-8"?><Response><Say>Thank you, a technician will be notified shortly.</Say><Hangup/></Response>),
      last_response.body
    )
  end
end

class TestSMSHandler < Minitest::Test
  include Rack::Test::Methods

  def app
    SMSHandler
  end

  def test_sms
    VCR.use_cassette('create_event_sms') do
      post '/', { 'From' => '+15555555555', 'Message' => '♫ Everything is broken ♫' }
    end
    assert_includes(last_response.headers['Content-Type'], 'text/xml')
    assert_equal(
      %q(<?xml version="1.0" encoding="UTF-8"?><Response><Message to="+15555555555">Thank you, a technician will be notified shortly.</Message></Response>),
      last_response.body
    )
  end
end

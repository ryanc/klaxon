require 'helper'
require 'pagerduty'

class TestCallHandler < Minitest::Test
  include Rack::Test::Methods

  def setup
    @pagerduty = Minitest::Mock.new
    @pagerduty.expect(:trigger, PagerdutyIncident.new('test', 'test'), [String, Hash])

    @caller = Faker::PhoneNumber.phone_number
    @recording_url = Faker::Internet.url
  end

  def app
    CallHandler
  end

  def test_greeting
    post '/greeting', { 'Caller' => @caller, 'RecordingUrl' => @recording_url }
    assert last_response.ok?
    assert_includes(last_response.headers['Content-Type'], 'text/xml')
    assert_equal(200, last_response.status)
    assert_equal(
      %Q(<?xml version="1.0" encoding="UTF-8"?><Response><Say>Please leave a message for the on call technician.</Say><Pause/><Record action="/call/voicemail"/></Response>),
      last_response.body
    )
  end

  def test_voicemail
    Pagerduty.stub :new, @pagerduty do
      post '/voicemail', { 'Caller' => @caller, 'RecordingUrl' => @recording_url }

      begin
        @pagerduty.verify
      rescue MockExpectationError => e
        flunk(e.message)
      else
        pass
      end
    end

    assert last_response.ok?
    assert_includes(last_response.headers['Content-Type'], 'text/xml')
    assert_equal(
      %Q(<?xml version="1.0" encoding="UTF-8"?><Response><Say>Thank you, a technician will be notified shortly.</Say><Hangup/></Response>),
      last_response.body
    )
  end
end

class TestSMSHandler < Minitest::Test
  include Rack::Test::Methods

  def setup
    @pagerduty = Minitest::Mock.new
    @pagerduty.expect(:trigger, PagerdutyIncident.new('test', 'test'), [String, Hash])

    @caller = Faker::PhoneNumber.phone_number
  end

  def app
    SMSHandler
  end

  def test_sms
    Pagerduty.stub :new, @pagerduty do
      post '/', { 'From' => @caller, 'Message' => '♫ Everything is broken ♫' }

      begin
        @pagerduty.verify
      rescue MockExpectationError => e
        flunk(e.message)
      else
        pass
      end
    end

    assert last_response.ok?
    assert_includes(last_response.headers['Content-Type'], 'text/xml')
    assert_equal(
      %Q(<?xml version="1.0" encoding="UTF-8"?><Response><Message to="#{@caller}">Thank you, a technician will be notified shortly.</Message></Response>),
      last_response.body
    )
  end
end

class TestWebHandler < Minitest::Test
  include Rack::Test::Methods

  def setup
    @pagerduty = Minitest::Mock.new
    @pagerduty.expect(:trigger, PagerdutyIncident.new('test', 'test'), [String, Hash])

    @caller = Faker::PhoneNumber.phone_number
    @name = Faker::Name.name
  end

  def app
    WebHandler
  end

  def test_render_form
    get '/'
    assert last_response.ok?
    assert_includes(last_response.headers['Content-Type'], 'text/html')
    assert_includes(last_response.body, '<form')
  end

  def test_post_form
    Pagerduty.stub :new, @pagerduty do
      post '/', { name: @name, phone: @caller, message: '♫ Everything is broken ♫' }
    end
    assert last_response.ok?
    assert_includes(last_response.headers['Content-Type'], 'text/html')
    assert_includes(last_response.body, '<form')
    assert_includes(last_response.body, 'A technician has been paged.')

    begin
      @pagerduty.verify
    rescue MockExpectationError => e
      flunk(e.message)
    else
      pass
    end
  end

  def test_validation_failure_name
    post '/', { name: '', phone: @caller, message: '♫ Everything is broken ♫' }
    assert_equal(400, last_response.status)
    assert_includes(last_response.body, 'All fields are required.')
    refute_includes(last_response.body, 'A technician has been paged.')

    post '/', { name: ' ', phone: @caller, message: '♫ Everything is broken ♫' }
    assert_equal(400, last_response.status)
    assert_includes(last_response.body, 'All fields are required.')
    refute_includes(last_response.body, 'A technician has been paged.')
  end

  def test_validation_failure_phone
    post '/', { name: @name, phone: '', message: '♫ Everything is broken ♫' }
    assert_equal(400, last_response.status)
    assert_includes(last_response.body, 'All fields are required.')
    refute_includes(last_response.body, 'A technician has been paged.')

    post '/', { name: @name, phone: ' ', message: '♫ Everything is broken ♫' }
    assert_equal(400, last_response.status)
    assert_includes(last_response.body, 'All fields are required.')
    refute_includes(last_response.body, 'A technician has been paged.')
  end

  def test_validation_failure_message
    post '/', { name: @name, phone: @caller, message: '' }
    assert_equal(400, last_response.status)
    assert_includes(last_response.body, 'All fields are required.')
    refute_includes(last_response.body, 'A technician has been paged.')

    post '/', { name: @name, phone: @caller, message: ' ' }
    assert_equal(400, last_response.status)
    assert_includes(last_response.body, 'All fields are required.')
    refute_includes(last_response.body, 'A technician has been paged.')
  end
end

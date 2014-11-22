require 'helper'
require 'app/helpers/pagerduty'

class TestPagerDutyGateway < Minitest::Test
  def setup
    @pagerduty = Minitest::Mock.new
    @pagerduty.expect(:trigger, PagerdutyIncident.new('test', 'test'), [String, Hash])

    @gw = PagerDutyGateway.new(ENV['PAGERDUTY_SERVICE_KEY'])
    @gw.pagerduty = @pagerduty

    @recording_url = Faker::Internet.url
    @caller = Faker::PhoneNumber.phone_number
    @name = Faker::Name.name
  end

  def test_voicemail_event
    @gw.trigger_voicemail_event(@caller, @recording_url)

    begin
      @pagerduty.verify
    rescue MockExpectationError => e
      flunk(e.message)
    else
      pass
    end
  end

  def test_sms_event
    @gw.trigger_sms_event(@caller, '♫ Everything is broken ♫')

    begin
      @pagerduty.verify
    rescue MockExpectationError => e
      flunk(e.message)
    else
      pass
    end
  end

  def test_web_event
    @gw.trigger_web_event(@name, @caller, '♫ Everything is broken ♫')

    begin
      @pagerduty.verify
    rescue MockExpectationError => e
      flunk(e.message)
    else
      pass
    end
  end
end

require 'helper'
require 'app/helpers/pagerduty'

class TestPagerDutyGateway < Minitest::Test
  def setup
    @pagerduty = Minitest::Mock.new
    @pagerduty.expect(:trigger, PagerdutyIncident.new('test', 'test'), [String, Hash])

    @gw = PagerDutyGateway.new(ENV['PAGERDUTY_SERVICE_KEY'])
    @gw.pagerduty = @pagerduty

    @sample_recording_url = 'http://api.twilio.com/2010-04-01/Accounts/AC00000000000000000000000000000000/Recordings/RE00000000000000000000000000000000'
  end

  def test_voicemail_event
    @gw.trigger_voicemail_event('+15555555555', @sample_recording_url)
    assert(@pagerduty.verify)
  end

  def test_sms_event
    @gw.trigger_sms_event('+15555555555', '♫ Everything is broken ♫')
    assert(@pagerduty.verify)
  end
end

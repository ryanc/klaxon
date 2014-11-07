class PagerDutyGateway
  HOST = 'events.pagerduty.com'
  PORT = 443
  PATH = '/generic/2010-04-15/create_event.json'

  attr_accessor :pagerduty

  def initialize(service_key)
    @pagerduty = Pagerduty.new(service_key)
  end

  def trigger_voicemail_event(caller, recording_url)
    description = "New voicemail from #{caller}"
    incident_key = "voicemail #{caller}"
    details = { caller: caller, voicemail: recording_url }
    @pagerduty.trigger(description, :incident_key => incident_key, :details => details)
  end

  def trigger_sms_event(caller, message)
    description = "New SMS from #{caller}"
    incident_key = "sms #{caller}"
    details = { caller: caller, message: message }
    @pagerduty.trigger(description, :incident_key => incident_key, :details => details)
  end
end

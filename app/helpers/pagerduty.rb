class PagerDutyGateway
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

  def trigger_web_event(name, phone, message)
    description = "New Web UI page from #{name}"
    incident_key = "web #{phone}"
    details = { name: name, phone: phone, message: message }
    @pagerduty.trigger(description, :incident_key => incident_key, :details => details)
  end
end

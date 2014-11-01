$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

require 'sinatra'
require 'twilio-ruby'
require 'logger'
require 'sinatra/base'
require 'pagerduty'
require 'dotenv'

class PagerdutyEvent
  def initialize(service_key)
    @pagerduty = Pagerduty.new(service_key)
  end

  def call(caller, recording_url)
    description = "New voicemail from #{caller}"
    incident_key = "voicemail #{caller}"
    details = { caller: caller, voicemail: recording_url }
    @pagerduty.trigger(description, :incident_key => incident_key, :details => details)
  end

  def sms(caller, message)
    description = "New SMS from #{caller}"
    incident_key = "sms #{caller}"
    details = { caller: caller, message: message }
    @pagerduty.trigger(description, :incident_key => incident_key, :details => details)
  end
end

class Handler < Sinatra::Base
  configure do
    Dotenv.load
    enable :logging
    set :service_key, ENV['PAGERDUTY_SERVICE_KEY']
  end
end

class CallHandler < Handler
  before do
    logger.debug("Parameters: #{params.inspect}")
    content_type 'text/xml'
    @caller = params[:Caller]
  end

  post '/greeting' do
    logger.info("Received a call from #{@caller}.")

    response = Twilio::TwiML::Response.new do |r|
      r.Say "Please leave a message for the on call technician."
      r.Pause
      r.Record :action => '/call/voicemail'
    end

    response.to_xml
  end

  post '/voicemail' do
    pagerduty = PagerdutyEvent.new(settings.service_key)
    logger.info("Received a voicemail from #{@caller}.")
    recording_url = params['RecordingUrl'] + '.wav'
    logger.info("Voicemail saved to #{recording_url}.")
    pagerduty.call(@caller, recording_url)

    response = Twilio::TwiML::Response.new do |r|
      r.Say "Thank you, a technician will be notified shortly."
      r.Hangup
    end

    response.to_xml
  end
end

class SMSHandler < Handler
  before do
    logger.debug("Parameters: #{params.inspect}")
    content_type 'text/xml'
    @caller = params[:From]
  end

  post '/' do
    pagerduty = PagerdutyEvent.new(settings.service_key)
    message = params['Body']
    logger.info("Received a SMS from #{@caller}: #{message}.")
    pagerduty.sms(@caller, message)

    response = Twilio::TwiML::Response.new do |r|
      r.Message "Thank you, a technician will be notified shortly.", :to => @caller
    end

    response.to_xml
  end
end

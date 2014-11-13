$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

require 'sinatra'
require 'twilio-ruby'
require 'logger'
require 'sinatra/base'
require 'pagerduty'
require 'dotenv'
require 'rack-flash'

require 'app/helpers/pagerduty'

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
    pagerduty = PagerDutyGateway.new(settings.service_key)
    logger.info("Received a voicemail from #{@caller}.")
    recording_url = params['RecordingUrl'] + '.wav'
    logger.info("Voicemail saved to #{recording_url}.")
    pagerduty.trigger_voicemail_event(@caller, recording_url)

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
    pagerduty = PagerDutyGateway.new(settings.service_key)
    message = params['Body']
    logger.info("Received a SMS from #{@caller}: #{message}.")
    pagerduty.trigger_sms_event(@caller, message)

    response = Twilio::TwiML::Response.new do |r|
      r.Message "Thank you, a technician will be notified shortly.", :to => @caller
    end

    response.to_xml
  end
end

class WebHandler < Handler
  use Rack::Flash

  configure do
    enable :sessions
  end

  before do
    logger.debug("Parameters: #{params.inspect}")
  end

  get '/' do
    erb :form
  end

  post '/' do
    invalid = [:name, :phone, :message].any? do |field|
      params[field].nil? || params[field].strip.empty?
    end

    if invalid
      flash.now[:error] = "All fields are required."
      status 400
    else
      pagerduty = PagerDutyGateway.new(settings.service_key)
      name = params['name']
      message = params['message']
      phone = params['phone']
      logger.info("Received a Web page from #{phone}: #{message}.")
      pagerduty.trigger_web_event(name, phone, message)
      flash.now[:success] = "A technician has been paged."
    end
    erb :form
  end
end

require 'rubygems'
require 'google/api_client'
require 'yaml'
require 'date'
require 'twilio-ruby'
require 'sinatra'
require 'builder'

#set some variables

#phone to call (your cell)
$myPhone = "+14151112222"

#url of where the app is run
$appUrl = "http://hostname:4567"

#from number registered with Twilio
$fromPhone = "+1415111222"

# initialize Twilio Api
twilio_yaml = YAML.load_file('.twilio-api.yaml')
@tClient = Twilio::REST::Client.new(twilio_yaml["account_sid"],twilio_yaml["auth_token"])

# initialize Google Api
oauth_yaml = YAML.load_file('.google-api.yaml')
client = Google::APIClient.new
client.authorization.client_id = oauth_yaml["client_id"]
client.authorization.client_secret = oauth_yaml["client_secret"]
client.authorization.scope = oauth_yaml["scope"]
client.authorization.refresh_token = oauth_yaml["refresh_token"]
client.authorization.access_token = oauth_yaml["access_token"]

if client.authorization.refresh_token && client.authorization.expired?
  client.authorization.fetch_access_token!
end


service = client.discovered_api('calendar', 'v3')

page_token = nil
result = result = client.execute(:api_method => service.events.list,
                                 :parameters => {'calendarId' => 'primary'})

#start a thread to check calendar every 3 minutes
$sum = 0
$description = nil
$location = nil
Thread.new do
  while true do
    sleep 3*60
      while true do
      tNow = Time.now
      tNow3 = Time.now + (3*60)
      events = result.data.items
      phoneRegex = /1?\W*([2-9][0-8][0-9])\W*([2-9][0-9]{2})\W*([0-9]{4})(\se?x?t?(\d*))?/
      #find last page of events and get events on that page
      if !(page_token = result.data.next_page_token)
        events.each do |e|
            begin
            #if an event is in the next 3 minutes, gets the phone number and call
              if (tNow ..tNow3).cover?(Time.parse(e.start.dateTime))
                $summary = e.summary
                $description = e.description
                e.description =~ phoneRegex
                phoneDescription = $&
                $location = e.location
                e.location =~ phoneRegex
                phoneLocation = $&
                #check if a phone number was found in either location or description, call, and pass the number to call flow.
                if (phoneLocation || phoneDescription)
                  print "calling ", e.summary, "\n"
                  if phoneLocation
                    $phone = phoneLocation
                  elsif phoneDescription
                    $phone = phoneDescription
                  end
                  @call = @tClient.account.calls.create(
                      :from => '$fromPhone',
                      :to => '$myPhone',
                      :method => 'GET',
                      :url => '$appUrl'
                    )
                end
              end
            rescue NoMethodError
            #all day event, no dateTime
            #  print e.summary, "All day or cancelled event, no meeting time","\n"
            end
        end
        print "got last page of events, breaking", "\n"
        break
      end
      result = result = client.execute(:api_method => service.events.list,
                                       :parameters => {'calendarId' => 'primary', 'pageToken' => page_token})
    end
  end
end

#setup Twilio Call flow
  get '/' do
    builder do |xml|
      xml.instruct!
      xml.Response do
        xml.Say("summary ", $summary, "description ", $description, "location ", $location)
        xml.Dial($phone)
      end
    end
  end
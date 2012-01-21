### Proof of concept Twilio application.
The application connects to my Google Calendar, finds an upcoming meeting with a phone number, and connects that number with my cell phone. Currently stateless and requires manual configuration.

### To get this working with your Google Calendar you need to:

1. create a Google Application: http://code.google.com/apis/accounts/docs/OAuth2.html#Registering
2. authorize your account for your application on the command line `google-api oauth-2-login --scope=https://www.googleapis.com/auth/calendar --client-id=CLIENT_ID --client-secret=CLIENT_SECRET`
3. setup the Twilio API: insert your `account_sid` and `auth_token` in `.twilio-api.yaml`

More information: http://code.google.com/apis/calendar/v3/using.html#auth

### TODO
If people find this useful it will be productized to include the following:

* more phone numbers logic (non-standard formats, conference dialing, if multiple participants auto conference creation, etc)
* web front end
* multiple users with user control panel
* get user's location and only call if the user is either moving or outside of specified geographic area (i.e not home or office)

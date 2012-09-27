# Who to email?
DESTINATION_EMAIL = 'YOUR_EMAIL_GOES_HERE'
FROM_EMAIL = 'YOUR_SENDING_ADDRESS_GOES_HERE'
USERNAME = 'YOUR_JOBMINE_USERNAME_GOES_HERE'

# Which file should Jobmon read for your password?
PWD_FILE = '__pwd'

#	What time does Jobmine open at in the mornings?
CLOSED_BEFORE = 8 # am - specified in 24h time.

#	What date should we stop checking Jobmine?
#	                  yyyy  mm  dd  hh
END_DATE = Time.new 2012, 10, 26, 13

#	Free API Key for PostageApp (postageapp.com)
POSTAGEAPP_API_KEY = "YOUR_POSTAGEAPP_API_KEY_HERE"

#	How often should the script check? (in minutes)
#	Give the value :cron to /not/ loop, and instead only do one 
CHECK_EVERY = 10

# Should we automatically daemonize the process?
DAEMONIZE = true

#	Files that could (but probably shouldn't)
CACHE_FILE = '__applications.json'

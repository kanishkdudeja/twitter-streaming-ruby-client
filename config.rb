# Twitter API connection configuration

# These 4 variables are declared as constants in the library.
# Changing them here will not make a difference.

# TWITTER_API_REQUEST_METHOD = 'GET'
# TWITTER_API_REQUEST_PROTOCOL = 'https'
# TWITTER_API_REQUEST_HOST = 'stream.twitter.com'
# TWITTER_API_REQUEST_PORT = 443

#This can be changed
TWITTER_API_REQUEST_PATH = '/1.1/statuses/filter.json'

# OAuth Credentials
CONSUMER_KEY = ''
CONSUMER_SECRET = ''
ACCESS_TOKEN = ''
ACCESS_SECRET = ''

# Condition to filter the tweets on. You can specify multiple 
# keywords separated by commas here.
TWEET_FILTER = 'track=football'
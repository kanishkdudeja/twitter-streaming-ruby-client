# Twitter API connection configuration

# These 3 variables are declared as constants in the library.
# Changing these here will not make a difference
# TWITTER_API_REQUEST_METHOD = 'GET'
# TWITTER_API_REQUEST_HOST = 'stream.twitter.com'
# TWITTER_API_REQUEST_PORT = 443

#This can be changed
TWITTER_API_REQUEST_PATH = '/1.1/statuses/filter.json'

# OAuth Credentials
CONSUMER_KEY = 'TK2mTP3QNFaZ4XHIojyc5cOjf'
CONSUMER_SECRET = 'aWUMLnnNnxJVaOXFTWriTtmDXgs0kA4mPwVMyJ9ijDpqleT68Z'
ACCESS_TOKEN = '141120086-XmYaLGcVUItyJL4x537fWMgCi1G3PQrhO0hygFbL'
ACCESS_SECRET = 'RTsU9yV0OOsARMsdx719wCfHzfRDmJWpV9DoaaRauJott'

# Condition to filter the tweets on. You can specify multiple 
# keywords separated by commas here.
TWEET_FILTER = 'track=football'
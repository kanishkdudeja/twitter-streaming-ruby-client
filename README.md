# Introduction

This Ruby library can be used to consume tweets from [Twitter's Streaming API](https://dev.twitter.com/streaming/public).

As an example, you can use this library to get all public tweets containing 'football' in real-time. Note that the streaming API only provides tweets which are being tweeted as of that time. It does not return historical data.

The library uses [EventMachine](https://github.com/eventmachine/eventmachine) under the hood for connection handling according to [Twitter's reconnection guidelines](https://dev.twitter.com/streaming/overview/connecting).

This library isn't available as a Ruby gem yet. You can however clone this Git repository to try this out!

# Authorization

You will need to generate OAuth tokens for your Twitter application in order to use this library. Instructions for the same are available [here](https://dev.twitter.com/oauth/overview/application-owner-access-tokens).

# Dependencies

You will need to install the following gems to use this library:

```
gem install simple_oauth
gem install eventmachine
gem install http_parser.rb
```

# Basic Usage

Here is some sample code to stream all tweets containing football in real time (The same code is available in example.rb in this repository)

```
lib_path = File.expand_path(File.join(File.dirname(__FILE__), 'lib/'))
$LOAD_PATH.unshift lib_path

TWITTER_API_REQUEST_PATH = '/1.1/statuses/filter.json'

# OAuth Credentials

CONSUMER_KEY = ''
CONSUMER_SECRET = ''
ACCESS_TOKEN = ''
ACCESS_SECRET = ''

# Condition to filter the tweets on. You can specify multiple 
# keywords separated by commas here.
TWEET_FILTER = 'track=football'

require 'twitter-streaming'

EventMachine::run {
  connection = TwitterStreaming::StreamingConnection.start(
    :path => TWITTER_API_REQUEST_PATH,
    :oauth    => { :consumer_key => CONSUMER_KEY, :consumer_secret => CONSUMER_SECRET, :access_key => ACCESS_TOKEN, :access_secret => ACCESS_SECRET},
    :query_params => TWEET_FILTER
  )

  connection.on_each_tweet do |item|
    puts "Received following tweet from Twitter:"
    puts item
  end

  connection.on_connection_success do |status_code|
    puts "Successful Connection: #{status_code}"
  end

  connection.on_connection_error do |status_code|
    puts "Error in connection: #{status_code}"
  end

  connection.on_scheduled_reconnect do |timeout|
    puts "Reconnecting in: #{timeout} seconds"
  end

  connection.on_max_reconnects_reached do
    puts "Connection halted due to max reconnects reached."```
  end

  connection.on_no_data_received do
    puts "No data received in the last 90 seconds. Attempting reconnect."
  end

  trap('TERM') {
    connection.terminate_connection
    EventMachine.stop if EventMachine.reactor_running?
  }
}
```


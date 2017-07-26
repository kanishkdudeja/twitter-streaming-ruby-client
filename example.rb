lib_path = File.expand_path(File.join(File.dirname(__FILE__), 'lib/'))
$LOAD_PATH.unshift lib_path

require_relative 'config'
require 'twitter-streaming'

EventMachine::run {
  connection = TwitterStreaming::StreamingConnection.start(
    :host => TWITTER_API_REQUEST_HOST,
    :port => TWITTER_API_REQUEST_PORT,
    :request_method => TWITTER_API_REQUEST_METHOD,
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
    puts "Connection halted due to max reconnects reached."
  end

  connection.on_no_data_received do
    puts "No data received in the last 90 seconds. Attempting reconnect."
  end

  trap('TERM') {
    stream.stop
    EventMachine.stop if EventMachine.reactor_running?
  }
}
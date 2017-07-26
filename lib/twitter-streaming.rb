# External dependencies
require 'uri'
require 'simple_oauth'
require 'http/parser'
require 'eventmachine'

# Module Code
require 'twitter-streaming/http_request'
require 'twitter-streaming/response_parser'
require 'twitter-streaming/reconnect_manager'
require 'twitter-streaming/streaming_connection'

module TwitterStreaming
end
module TwitterStreaming

class StreamingConnection < EventMachine::Connection

  #Some constants for the request
  REQUEST_METHOD = "GET"
  REQUEST_PROTOCOL = "https"
  HOST = "stream.twitter.com"
  PORT = 443

  #As per Twitter recommendations
  NO_DATA_RECEIVED_TIMEOUT = 90

  #Check health of connection every 10 seconds
  CONNECTION_HEALTH_CHECK_INTERVAL = 10

  #Holds the time object at which the data was last received from the network loop
  attr_accessor :data_last_received_at

  #Boolean indicating whether the connection was intentionally closed(true), or whether it closed due to a network error(false)
  attr_accessor :intentionally_closed

  #Integer denoting the status code of the last request. 0 if the request failed due to a network failure
  attr_accessor :last_status_code

  def initialize(options={})
    @options = options
    @reconnect_manager = TwitterStreaming::ReconnectManager.new

    @data_last_received_at = nil
    @intentionally_closed = false
  end

  #This function attempts to start the TCP connection on the specified host and port. The third parameter(self) passed to the 
  #EventMachine's connect function is the object on which the callbacks should be called.
  def self.start(options = {})
    connection = EventMachine.connect HOST, PORT, self, options
    return connection
  end

  #The following callbacks are called by the EventMachine event loop. 

  #Called after the network connection has been established.
  def post_init
    @healthcheck_poller = EventMachine.add_periodic_timer(CONNECTION_HEALTH_CHECK_INTERVAL) do
      if @intentionally_closed
        @healthcheck_poller.cancel
      elsif (@data_last_received_at) && ((Time.now - @data_last_received_at) >= NO_DATA_RECEIVED_TIMEOUT)
        no_data_received
        close_connection
      end
    end
  end

  #Called when the connection is closed. Can be due to any of the following: we close the connection intentionally,
  # of the remote server closes the connection, or if the connection drops due to a network error
  def unbind
    if @current_state == 'streaming'
      @parser.parse_unflushed_data
    end

    if !@intentionally_closed
      setup_reconnect
    end

    execute_callback(@connection_close_callback)
    @current_state = 'init'
  end

  #Called when the TCP connection attempt is successful. This is called after post_init in case of a successful connection. 
  def connection_completed
    if REQUEST_PROTOCOL == 'https'
      start_tls
    end

    #Resets connection state
    flush_connection_state

    #Constructing request hash
    request_options = {}
    request_options[:request_method] = REQUEST_METHOD
    request_options[:request_protocol] = REQUEST_PROTOCOL
    request_options[:host] = HOST
    request_options[:url_path] = @options[:path]
    request_options[:query_params] = @options[:query_params]
    request_options[:request_body] = @options[:request_body]
    request_options[:oauth] = @options[:oauth]

    request = TwitterStreaming::HTTPRequest.new(request_options)

    request_string = request.to_string

    #Sending raw request data over socket
    send_data request_string
  end

  #Called whenever data is received by the network connection
  def receive_data(data)
    @data_last_received_at = Time.now

    @parser.parse_data(data)
  end

  #The following callbacks can be registered by the client.
  #This callback can be registered to get each tweet received on the connection
  def on_each_tweet(&block)
    @each_tweet_callback = block
  end

  #This callback can be invoked to get notified of a successful sconnection
  def on_connection_success &block
    @connection_success_callback = block
  end

  #This callback can be registered to get notified of a connection error
  def on_connection_error &block
    @connection_error_callback = block
  end

  #This callback can be registered to get notified of scheduled reconnects
  def on_scheduled_reconnect &block
    @reconnect_callback = block
  end

  # Called when no data has been received for NO_DATA_TIMEOUT seconds.
  def on_no_data_received &block
    @no_data_received_callback = block
  end

  #This callback can be registered to process code if the MAX_RECONNECTS value is reached
  def on_max_reconnects_reached &block
    @maxiumum_reconnects_reached_callback = block
  end

  #This callback can be registered to get notified of connection closure
  def on_connection_close &block
    @connection_close_callback = block
  end

  #This flushes the current state of the connection upon a reconnect attempt
  def flush_connection_state
    @last_status_code = 0
    @current_state = 'init'

    @parser  = TwitterStreaming::ResponseParser.new
    @parser.on_http_success do |status_code|
      @current_state = 'streaming'
      @reconnect_manager.reset_state
      @last_status_code = status_code
      execute_callback(@connection_success_callback, status_code)
    end
    @parser.on_http_error do |status_code|
      execute_callback(@connection_error_callback, status_code)
      @last_status_code = status_code
    end
    @parser.on_each_line do |line|
      execute_callback(@each_tweet_callback, line)
    end
    #@parser.on_parse_error do
      #execute_callback(@connection_error_callback, 'Parse Error')

      #Closing the connection so that it can be re-attempted again
      #close_connection
    #end
  end

  #This function sets up a reconnect as per Twitter Recommendations
  def setup_reconnect
    delay = @reconnect_manager.get_next_reconnect_delay(@last_status_code)

    if delay == -1
      execute_callback(@maxiumum_reconnects_reached_callback)
      terminate_connection
    elsif delay == 0
      execute_callback(@reconnect_callback, 0)
      attempt_reconnect
    else
      execute_callback(@reconnect_callback, delay.to_f/1000)
      EventMachine.add_timer(delay.to_f/1000) do
        attempt_reconnect
      end
    end
  end

  #This functions attempts the reconnect immediately
  def attempt_reconnect
    #The reconnect method called below is provided by EventMachine
    reconnect HOST, PORT
  end

  #This function is called by the code when no data is received over the connection after waiting for NO_DATA_RECEIVED_TIMEOUT seconds 
  def no_data_received
    execute_callback(@no_data_received_callback)

    #The connection is closed so that it can be re-attempted again
    close_connection
  end

  #This function is a utility function for invoking callbacks
  def execute_callback(callback, *args)
    callback.call(*args) if callback
  end

  #This function is for intentially terminating the connection. Called when max connection attempts is reached or when the script halts due to some reason
  def terminate_connection
    @intentionally_closed = true
    close_connection
  end

end

end
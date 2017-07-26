module TwitterStreaming

class ReconnectManager

#Constants as per Twitter Recommendations

#Boolean denoting whether the first reconnect should be immediate or not
FIRST_IMMEDIATE_RECONNECT = true

#Attempt to reconnect 250MS after the first network failure
NETWORK_FAILURE_DELAY_FIRST_RECONNECT = 250 #250MS
NETWORK_FAILURE_DELAY_ADD_FACTOR = 250 #add 250MS each time for subsequent reconnects
NETWORK_FAILURE_DELAY_MAX = 16000 #16 seconds

#Attempt to reconnect 5S after the first HTTP request failure
HTTP_FAILURE_DELAY_FIRST_RECONNECT = 5000 #5 seconds
HTTP_FAILURE_DELAY_MULTIPLY_FACTOR = 2 #multiply by 2(double) each time for subsequent reconnects
HTTP_FAILURE_DELAY_MAX = 320000 #320 seconds

attr_accessor :network_failure_last_reconnect_delay
attr_accessor :http_failure_last_reconnect_delay

attr_accessor :num_retries

def initialize
  @network_failure_last_reconnect_delay = 0
  @http_failure_last_reconnect_delay = 0
  @num_retries = 0
end

#This function takes the status code of the last reconnect request and calculates whether or not the next reconnection
#attempt should occur. If the next reconnect should not occur, it returns -1, otherwise, it returns the delay(integer in milliseconds)
#after which the client should try to attempt the connect again
def get_next_reconnect_delay status_code

  if FIRST_IMMEDIATE_RECONNECT == true
    if @num_retries == 0
      @num_retries += 1
      return 0
    end
  end

  @num_retries += 1

  #Status_code = 0 means that a network failure took place.
  if status_code == 0
    if @network_failure_last_reconnect_delay == 0
      delay = NETWORK_FAILURE_DELAY_FIRST_RECONNECT
    elsif @network_failure_last_reconnect_delay == -1
      delay = -1
    else
      delay = @network_failure_last_reconnect_delay + (NETWORK_FAILURE_DELAY_ADD_FACTOR*(@num_retries-1))
      if delay > NETWORK_FAILURE_DELAY_MAX
        delay = -1
      end
    end
    @network_failure_last_reconnect_delay = delay

  else
    if @http_failure_last_reconnect_delay == 0
      delay = HTTP_FAILURE_DELAY_FIRST_RECONNECT
    elsif @http_failure_last_reconnect_delay == -1
      delay = -1
    else
      delay = @http_failure_last_reconnect_delay * HTTP_FAILURE_DELAY_MULTIPLY_FACTOR
      if delay > HTTP_FAILURE_DELAY_MAX
        delay = -1
      end
    end
    @http_failure_last_reconnect_delay = delay
  end

  return delay
end

#This function should be called by the caller upon a successful connection attempt. This resets last reconnect delays
#so as to start from a fresh plate
def reset_state
  @network_failure_last_reconnect_delay = 0
  @http_failure_last_reconnect_delay = 0
  @num_retries = 0
end

end

end
module TwitterStreaming

#This class uses HTTPParser to parse the response incrementally from the current_streaming connection
class ResponseParser < Http::Parser

  #The constructor registers callbacks for the HTTP parser object and initializes a new BufferedTokenizer object
  def initialize
  	@buffer_tokenizer  = BufferedTokenizer.new("\r")
  	@current_stream  = ''

  	self.on_headers_complete = method(:on_headers_complete_callback)
    self.on_body = method(:on_body_callback)
  end

  #Invoked when 200 status code is parsed from the headers
  def on_http_success &block
	@http_success_callback = block
  end

  #Invoked when an an error status code(!=200) is parsed from the headers
  def on_http_error &block
	@http_error_callback = block
  end

  #Invoked on parsing each line from the response
  def on_each_line &block
	@each_line_callback = block
  end

  #Invoked when an error was encountered while parsing the response
  def on_parse_error &block
	@parse_error_callback = block
  end

  #This callback is called when HTTPParser finishes parsing the headers
  def on_headers_complete_callback headers
  	@status_code = self.status_code.to_i
	if @status_code == 200
	  execute_callback(@http_success_callback, 200)
	else
	  execute_callback(@http_error_callback, @status_code)
	end
  end

  #This callback is called when the HTTPParser finishes parsing the body
  def on_body_callback(data)
  	begin
      @buffer_tokenizer.extract(data).each do |line|
        parse_line(line)
      end
      @current_stream  = ''
    rescue => e
      execute_callback(@parse_error_callback, e.to_s)
      return
    end
  end

  #This function is used by the caller to feed raw data into the parser so that the parser can parse it
  def parse_data(data)
  	begin
  	  self << data
  	rescue
  	  #do nothing
  	end
  end

  #This function is used to check if the parsed line is valid JSON or not. If it is valid JSON, the corresponding callback is invoked.
  def parse_line line
	line_trimmed = line.strip

	unless line_trimmed.empty?
	  if line_trimmed[0,1] == '{' || line_trimmed[line_trimmed.length-1,1] == '}'
	    @current_stream << line_trimmed
	    if looks_like_json?(@current_stream)
	      execute_callback(@each_line_callback, @current_stream)
	      @current_stream = ''
	    end
	  else
	  	execute_callback(@parse_error_callback, 'Invalid JSON')
	  end
	else
	  execute_callback(@parse_error_callback, 'Invalid JSON')
	end
  end

  #This function parses the unflushed data before a reconnection reattempt
  def parse_unflushed_data
    parse_line(@buffer_tokenizer.flush)
  end

  #This function checks if the string looks like JSON, by checking if the first and last characters in the string are { and } respectively
  def looks_like_json?(string)
  	string[0,1] == '{' && string[string.length-1,1] == '}'
  end

  #This function is a utility function for invoking callbacks
  def execute_callback(callback, *args)
    callback.call(*args) if callback
  end
end

end


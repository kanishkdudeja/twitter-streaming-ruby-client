module TwitterStreaming

class HTTPRequest

  def initialize(options = {})
    @options = options

    @request_url = request_url
    @request_body = request_body
  end

  def request_uri
    if @options[:request_method].to_s.upcase == 'GET'
      @request_uri = @options[:url_path] + "?#{@options[:query_params]}"
    end

    @request_uri
  end

  def request_url
    protocol_prefix = @options[:request_protocol] == 'https' ? 'https://' : 'http://'
    protocol_prefix + @options[:host] + request_uri
  end

  def request_body
    if @options[:request_method].to_s.upcase != 'GET'
      return @options[:request_body]
    else
      return ""
    end
  end

  def to_string
    data = []

    data.push "#{@options[:request_method]} #{@request_uri} HTTP/1.1"
    data.push "Host: #{@options[:host]}"
    data.push 'Accept: */*'
    data.push "User-Agent: #{@options[:user_agent]}" if @options[:user_agent]

    data.push "Authorization: #{generate_oauth_header}"

    if ['POST', 'PUT'].include?(@options[:request_method])
      data.push << "Content-type: #{@options[:content_type]}"
      data.push << "Content-length: #{@request_body.length}"
    end

    data.push "\r\n"

    string = data.join("\r\n") + @request_body

    return string
  end

  def generate_oauth_header
    oauth = {
      :consumer_key => @options[:oauth][:consumer_key],
      :consumer_secret => @options[:oauth][:consumer_secret],
      :token => @options[:oauth][:access_key],
      :token_secret => @options[:oauth][:access_secret]
    }

    SimpleOAuth::Header.new(@options[:request_method], @request_url, {}, oauth)
  end

  end

end
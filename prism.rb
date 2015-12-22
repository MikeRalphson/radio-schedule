require 'net/https'
require 'json'
require 'cgi'

# Certificate for accessing Forge APIs
raise "Please set the HTTPS_CERT_FILE environment variable" if ENV['HTTPS_CERT_FILE'].nil?
HTTPS_CERT = File.read(ENV['HTTPS_CERT_FILE'])


class PRISM
  def initialize(endpoint="https://prism-admin.cloud.bbc.co.uk/api")
    @endpoint = endpoint
  end

  def raw_messages(network, date, limit=100)
    get('/messages/raw', :type => 'network', :id => network, :from => date, :to => date + 1, :pageSize => limit)
  end

  def raw_message(message_id)
    get("/messages/raw/xml/#{message_id}")
  end

  def get(feed, args={})
    uri = URI.parse(@endpoint + feed.to_s)
    params = []
    args.keys.sort {|a,b| a.to_s <=> b.to_s}.each do |key|
      if args[key].is_a?(Array)
        args[key].each do |value|
          params << CGI.escape(key.to_s) + '=' + CGI.escape(value.to_s)
        end
      else
        params << CGI.escape(key.to_s) + '=' + CGI.escape(args[key].to_s)
      end
    end
    uri.query = params.join('&')
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 10
    http.read_timeout = 20

    if uri.scheme == "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      if HTTPS_CERT
        http.key = OpenSSL::PKey::RSA.new(HTTPS_CERT)
        http.cert = OpenSSL::X509::Certificate.new(HTTPS_CERT)
      end
    end

    req = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(req)

    # Check that the response is success
    response.value

    if response['Content-Type'].match(%r|^application/json|)
      data = JSON.parse(response.body)
      data['results']
    elsif response['Content-Type'].match(%r|^application/xml|)
      Nokogiri::XML(response.body)
    else
      raise "Unable to parse PRISM response: #{response['Content-Type']}"
    end
  end
end

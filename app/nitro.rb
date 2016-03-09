require 'net/https'
require 'json'
require 'cgi'


class Nitro
  attr_accessor :endpoint
  attr_accessor :http_proxy

  # API Key for accessing Nitro
  raise "Please set the NITRO_API_KEY environment variable" if ENV['NITRO_API_KEY'].nil?
  API_KEY = ENV['NITRO_API_KEY']

  def initialize(endpoint="http://programmes.api.bbc.com/nitro/api/")
    @endpoint = endpoint
  end
  
  def schedule(service_id, date)
    get(:schedules,
      :sid => service_id,
      :schedule_day => date,
      :mixin => 'ancestor_titles',
      :page_size => 100
    )
  end

  def service(service_id)
    results = get(:services,
      :sid => service_id,
      :page_size => 1
    )
    if results['items']
      results['items'].first
    end
  end

  def programme(pid)
    results = get(:programmes,
      :pid => pid,
      :page_size => 1
    )
    if results['items']
      results['items'].first
    end
  end

  def get(feed, args={})
    uri = URI.parse(@endpoint + feed.to_s)
    params = ["api_key=#{API_KEY}"]
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

    if http_proxy 
      proxy_uri = URI.parse(http_proxy)
      http = Net::HTTP::Proxy(proxy_uri.host, proxy_uri.port).new(uri.host, uri.port)
    else
      http = Net::HTTP.new(uri.host, uri.port)
    end

    http.open_timeout = 10
    http.read_timeout = 20

    req = Net::HTTP::Get.new(uri.request_uri)
    req['User-Agent'] = 'BBC Programme Stats (by http://njh.me/)'
    req['Accept'] = 'application/json'
    response = http.request(req)

    # Check that the response is success
    response.value

    if response['Content-Type'].match(%r|^application/json|)
      data = JSON.parse(response.body)
      data['nitro']['results']
    else
      raise 'Nitro did not response with JSON'
    end
  end
end

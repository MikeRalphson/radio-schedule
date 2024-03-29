require 'sinatra/base'
require 'logger'
require 'nitro'
require 'pips3-api'

class RadioScheduleApp < Sinatra::Application

  nitro = Nitro.new
  nitro.http_proxy = ENV["HTTP_PROXY"]

  Pips3Api::Base.logger = Logger.new(STDOUT)
  Pips3Api::Base.logger.level = Logger::INFO
  Pips3Api::Base.config = {
    :endpoint => 'https://api.live.bbc.co.uk/pips/api/v1',
    :certificate_path => ENV["HTTPS_CERT_FILE"],
    :proxy => ENV["HTTP_PROXY"],
  }

  SERVICES = [
    {:sid => 'bbc_radio_four_extra', :title => 'BBC Radio 4 Extra'},
    {:sid => 'bbc_radio_fourfm', :title => 'BBC Radio 4 FM'},
    {:sid => 'bbc_radio_three', :title => 'BBC Radio 3'},
  ]

  set :static_cache_control, [:public, :max_age => 600]

  helpers do
    def pips_inspector(pid)
      "<a href='https://api.live.bbc.co.uk/pips/inspector/pip/#{pid}'>#{pid}</a>"
    end
  end

  before do
    if settings.environment == :production
      # Hack to fix redirects using the wrong protocol (thanks to broken proxy)
      def request.scheme
        'https'
      end

      response.headers['Strict-Transport-Security'] = 'max-age=31536000'
      Pips3Api::Base.config[:endpoint] = ENV['PIPS_ENDPOINT']
      nitro.endpoint = ENV['NITRO_ENDPOINT']
    else
      # Development Mode
      Pips3Api::Base.config[:endpoint] = 'https://api.test.bbc.co.uk/pips/api/v1'
      nitro.endpoint = "http://nitro-e2e.api.bbci.co.uk/nitro-e2e/api/"
    end
  end

  get '/' do
    cache_control :public, :max_age => 3600
    redirect "/schedules/#{SERVICES.first[:sid]}/#{Date.today}"
  end

  get '/status' do
    "OK"
  end

  get %r{/schedules/(\w+)/(\d{4}-\d{2}-\d{2})$} do |service_id,date|
    @date = Date.parse(date)
    @service = nitro.service(service_id)
    if @service.nil?
      status 404
      return "Service Not Found"
    end

    @page_title = "#{@service['name']} - #{@date}"
    @rows = []

    schedule = nitro.schedule(@service['sid'], @date)
    schedule['items'].each do |broadcast|
      broadcast['episode_pid'] = broadcast['broadcast_of'].find {|item| item['result_type'] == 'episode'}['pid']
      broadcast['version_pid'] = broadcast['broadcast_of'].find {|item| item['result_type'] == 'version'}['pid']

      if broadcast['published_time']
        unless broadcast['published_time']['start'].nil?
          broadcast['published_start_time'] = Time.parse(broadcast['published_time']['start'])
        end
        unless broadcast['published_time']['end'].nil?
          broadcast['published_end_time'] = Time.parse(broadcast['published_time']['end'])
        end
      end

      if broadcast['tx_time']
        unless broadcast['tx_time']['start'].nil?
          broadcast['accurate_start_time'] = Time.parse(broadcast['tx_time']['start'])
        end
        unless broadcast['tx_time']['end'].nil?
          broadcast['accurate_end_time'] = Time.parse(broadcast['tx_time']['end'])
        end
      end

      @rows << broadcast
    end

    cache_control :public, :max_age => 1200
    erb :index
  end

  get %r{/episodes/(\w+)$} do |episode_pid|
    @episode = nitro.programme(episode_pid)
    if @episode.nil?
      status 404
      return "Episode Not Found"
    end

    content_type :json
    cache_control :public, :max_age => 600
    @episode.to_json
  end

  get %r{/broadcasts/(\w+)$} do |broadcast_pid|
    @broadcast = Pips3Api::Broadcast.find(broadcast_pid)
    if @broadcast.nil?
      status 404
      return "Broadcast Not Found"
    end

    content_type :json
    cache_control :private, :max_age => 0
    @broadcast.attributes.to_json
  end

  post %r{/broadcasts/(\w+)$} do |broadcast_pid|
    @broadcast = Pips3Api::Broadcast.find(broadcast_pid)
    if @broadcast.nil?
      status 404
      return "Broadcast Not Found"
    end

    if params['accurate_start'].nil? or params['accurate_end'].nil?
      status 400
      return "Missing accurate_start or accurate_end"
    end

    # Update the broadcast with the new accurate start/end
    @broadcast.accurate_start = Time.parse(params['accurate_start'])
    @broadcast.accurate_end = Time.parse(params['accurate_end'])
    @broadcast.save!

    cache_control :private, :max_age => 0
    "OK"
  end

end

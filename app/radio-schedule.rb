require 'sinatra/base'
require 'logger'
require 'nitro'

class RadioScheduleApp < Sinatra::Application

  nitro = Nitro.new

  radio_services = [
    :bbc_1xtra,
    :bbc_radio_one,
    :bbc_radio_two,
    :bbc_radio_three,
    :bbc_radio_fourfm,
    :bbc_radio_fourlw,
    :bbc_radio_four_extra,
    :bbc_radio_five_live,
    :bbc_radio_five_live_sports_extra,
    :bbc_6music,
    :bbc_asian_network,
    :bbc_world_service,
    :bbc_radio_scotland_fm,
    :bbc_radio_nan_gaidheal,
    :bbc_radio_ulster,
    :bbc_radio_foyle,
    :bbc_radio_wales,
    :bbc_radio_cymru
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
    end
  end

  get '/' do
    cache_control :public, :max_age => 3600
    redirect "/schedules/bbc_radio_four_extra/#{Date.today}"
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

end

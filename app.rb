#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require './nitro'
require './prism'


prism = PRISM.new
nitro = Nitro.new


def inner_text(xml, path)
  node = xml.at(path)
  unless node.nil?
    node.inner_text
  end
end


get '/' do
  redirect "/#{Date.today}"
end

get %r{/(\d{4}-\d{2}-\d{2})$} do |date|

  @date = Date.parse(date)
  
  messages = prism.raw_messages('bbc_radio_fourfm', @date)
  messages.each do |message|
    raw_xml = prism.raw_message(message['keyfield'])
    message['proteus_no'] = inner_text(raw_xml, 'AssetInfo/GENE_PROD_NO')
    message['proteus_uuid'] = inner_text(raw_xml, 'AssetInfo/GENE_PROD_UUID')
    message['accurate_start_time'] = Time.at(message['rawvcsStartTime'] / 1000)
    message['accurate_end_time'] = message['accurate_start_time'] + message['rawvcsDuration']
    message['raw_url'] = 'https://prism-admin.cloud.bbc.co.uk/api/messages/raw/xml/' + message['keyfield']

    message['sort_time'] = message['accurate_start_time']
  end
  
  @rows = messages

  schedule = nitro.schedule('bbc_radio_fourfm', @date)
  schedule['items'].each do |broadcast|
    ids = broadcast['ids']['id']
    proteus_id = ids.find {|id| id['type'] == 'bbc_proteus_tx_crid'}
 
    episode = broadcast['broadcast_of'].find {|item| item['result_type'] == 'episode'}
    broadcast['programme_url'] = 'http://www.bbc.co.uk/programmes/'+episode['pid']
    broadcast['programme_title'] = broadcast['ancestor_titles'].map {|item| item['title']}.uniq.compact.join(' - ')
   
    if broadcast['published_time']
      broadcast['published_start_time'] = Time.parse(broadcast['published_time']['start'])
      broadcast['published_end_time'] = Time.parse(broadcast['published_time']['end'])
    end

    matched = false
    if proteus_id and proteus_id['$'] =~ %r|bbc.co.uk/r/(\w+)|
      broadcast['pips_proteus_no'] = $1
      messages.each do |message|
        if message['proteus_no'] == broadcast['pips_proteus_no'] and
          broadcast['published_start_time'] <= message['accurate_start_time']
          matched = true
          message['status'] = 'success'
          message.merge!(broadcast)
          break
        end
      end
    end

    if matched == false
      broadcast['sort_time'] = broadcast['published_start_time']
      @rows << broadcast
    end
  end
  
  @rows.each do |row|
    if row['proteus_no'] and !row['pid']
      row['status'] = 'danger'
    end
  end

  @rows.sort_by! {|item| item['sort_time']}

  erb :index
end

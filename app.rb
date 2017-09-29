require 'sinatra'
require 'yaml'
require 'json'
require 'cgi'
require_relative 'lib/client/kollus_api_client'
require_relative 'lib/client/kollus_video_gateway_client'
require_relative 'lib/container/service_account'

exists_config = File.file?('config.yml')
set :exists_config, exists_config
if exists_config
  config = YAML.load_file('config.yml')
  service_account = ServiceAccount.new(key: config['kollus']['service_account']['key'],
                                       api_access_token: config['kollus']['service_account']['api_access_token'],
                                       custom_key: config['kollus']['service_account']['custom_key'])
  kollus_api_client = KollusApiClient.new(service_account: service_account,
                                          domain: config['kollus']['domain'],
                                          version: config['kollus']['version'])

  kollus_video_gateway_client = KollusVideoGatewayClient.new(service_account: service_account,
                                                             domain: config['kollus']['domain'],
                                                             version: config['kollus']['version'])

  set :kollus, config['kollus']
  set :service_account, service_account
  set :kollus_api_client, kollus_api_client
  set :kollus_video_gateway_client, kollus_video_gateway_client
end

enable :sessions

get '/' do
  unless session[:client_user_id].nil?
    redirect to('/channel')
  end

  locals = {
    client_user_id: session[:client_user_id],
    exists_config: settings.exists_config,
    kollus: settings.kollus
  }

  erb :index, locals: locals
end

get '/logout' do
  session[:client_user_id] = nil

  redirect to('/')
end

post '/' do
  session[:client_user_id] = params[:client_user_id]

  redirect to('/channel')
end

get /\/channel\/?(.+)?/ do |channel_key|
  if session[:client_user_id].nil?
    redirect to('/')
  end

  locals = {
    exists_config: settings.exists_config,
    kollus: settings.kollus,
    client_user_id: session[:client_user_id]
  }

  channels = []
  media_contents = []
  if settings.exists_config
    # @type [KollusApiClient] kollus_api_client
    kollus_api_client = settings.kollus_api_client
    channels = kollus_api_client.channels
    # channel = nil

    unless channels.empty?
      channel = channel_key.nil? ? channels.first : channels.find { |c| c.key == channel_key }
      channel_key = channel.key unless channel.nil?
    end

    # raise 'Channel is not exists.' if channel_key.nil?

    result = kollus_api_client.find_channel_media_contents(channel_key: channel_key)
    media_contents = result[:items]
  end

  locals[:channels] = channels
  locals[:channel_key] = channel_key
  locals[:media_contents] = media_contents

  erb :channel, locals: locals
end

post /\/auth\/play-video-url\/(.+)\/(.+)/ do |channel_key, upload_file_key|
  if session[:client_user_id].nil?
    redirect to('/')
  end

  # @type [KollusApiClient] kollus_api_client
  kollus_api_client = settings.kollus_api_client
  # @type [KollusVideoGatewayClient] kollus_video_gateway_client
  kollus_video_gateway_client = settings.kollus_video_gateway_client

  # @type [MediaContent] media_content
  media_content = kollus_api_client.channel_media_content(
    channel_key: channel_key,
    upload_file_key: upload_file_key
  )

  content_type :json, 'charset' => 'utf-8'
  {
    title: media_content.title,
    web_token_url: kollus_video_gateway_client.web_token_url_by_media_content_key(
      media_content_key: media_content.media_content_key,
      client_user_id: session[:client_user_id],
      options: {
        expire_time: settings.kollus['play_options']['expire_time'], # 1day
        autoplay: true
      }
    )
  }.to_json
end

post /\/auth\/download-video-url\/(.+)\/(.+)/ do |channel_key, upload_file_key|
  if session[:client_user_id].nil?
    redirect to('/')
  end

  # @type [KollusApiClient] kollus_api_client
  kollus_api_client = settings.kollus_api_client
  # @type [KollusVideoGatewayClient] kollus_video_gateway_client
  kollus_video_gateway_client = settings.kollus_video_gateway_client

  # @type [MediaContent] media_content
  media_content = kollus_api_client.channel_media_content(
    channel_key: channel_key,
    upload_file_key: upload_file_key
  )

  content_type :json, 'charset' => 'utf-8'
  {
    title: media_content.title,
    web_token_url: kollus_video_gateway_client.web_token_url_by_media_content_key(
      media_content_key: media_content.media_content_key,
      client_user_id: session[:client_user_id],
      options: {
        expire_time: settings.kollus['play_options']['expire_time'], # 1day
        download: true
      }
    )
  }.to_json
end

post /\/auth\/play-video-playlist\/(.+)/ do |channel_key|
  if session[:client_user_id].nil?
    redirect to('/')
  end

  # @type [KollusApiClient] kollus_api_client
  kollus_api_client = settings.kollus_api_client
  # @type [KollusVideoGatewayClient] kollus_video_gateway_client
  kollus_video_gateway_client = settings.kollus_video_gateway_client

  media_items = params['selected_media_items'].map do |index, media_item|
    media_content = kollus_api_client.channel_media_content(
      channel_key: channel_key,
      upload_file_key: media_item['upload_file_key']
    )

    MediaItem.new({ media_content_key: media_content.media_content_key })
  end

  content_type :json, 'charset' => 'utf-8'
  {
    web_token_url: kollus_video_gateway_client.web_token_url_by_media_items(
      media_items: media_items,
      client_user_id: session[:client_user_id],
      options: {
        kind: 'si',
        expire_time: settings.kollus['play_options']['expire_time'], # 1day
        autoplay: true
      }
    )
  }.to_json
end

post /\/auth\/download-multi-video\/(.+)/ do |channel_key|
  if session[:client_user_id].nil?
    redirect to('/')
  end

  # @type [KollusApiClient] kollus_api_client
  kollus_api_client = settings.kollus_api_client
  # @type [KollusVideoGatewayClient] kollus_video_gateway_client
  kollus_video_gateway_client = settings.kollus_video_gateway_client

  media_items = params['selected_media_items'].map do |index, media_item|
    media_content = kollus_api_client.channel_media_content(
      channel_key: channel_key,
      upload_file_key: media_item['upload_file_key']
    )

    MediaItem.new({ media_content_key: media_content.media_content_key })
  end

  content_type :json, 'charset' => 'utf-8'
  {
    web_token_url: kollus_video_gateway_client.web_token_url_by_media_items(
      media_items: media_items,
      client_user_id: session[:client_user_id],
      options: {
        kind: 'si',
        expire_time: settings.kollus['play_options']['expire_time'], # 1day
      }
    )
  }.to_json
end

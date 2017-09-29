require 'jwt'
require_relative '../container/service_account'
require_relative '../container/media_item'

class KollusVideoGatewayClient
  attr_accessor(:service_account, :domain, :version, :scheme)

  # initialize
  #
  # @param [ServiceAccount] service_account
  # @param [String] domain
  # @param [String] version
  def initialize(service_account:, domain: 'kr.kollus.com', version: '0')
    @service_account = service_account
    @domain = domain
    @version = version
    @scheme = 'http'
  end

  # video_gateway_domain
  #
  # @return [String]
  def video_gateway_domain()
    'v.' + @domain
  end

  # web_token_by_media_items
  #
  # @param [String] media_content_key
  # @param [String|Nil] client_user_id
  # @param [Hash] options
  # @return [String]
  def web_token_by_media_content_key(media_content_key:, client_user_id: nil, options: {})
    media_item = { media_content_key: media_content_key }
    media_item[:media_profile_key] = media_item[:media_profile_key] unless options[:media_profile_key].nil?
    media_item[:is_intro] = media_item[:is_intro] unless options[:is_intro].nil?
    media_item[:is_seekable] = media_item[:is_seekable] unless options[:is_seekable].nil?
    media_item[:seekable_end] = media_item[:seekable_end] unless options[:seekable_end].nil?
    media_item[:disable_playrate] = media_item[:disable_playrate] unless options[:disable_playrate].nil?
    media_items = [MediaItem.new(media_item)]

    web_token_by_media_items(media_items: media_items, client_user_id: client_user_id, options: options)
  end

  # web_token_by_media_items
  #
  # @param [Array<MediaItem>] media_items
  # @param [String|Nil] client_user_id
  # @param [Hash] options
  # @return [String]
  def web_token_by_media_items(media_items:, client_user_id: nil, options: {})
    security_key = options[:security_key].nil? ? @service_account.security_key : options[:security_key]
    payload = { mc:[] }

    media_items.each do |media_item|
      next unless media_item.is_a?(MediaItem)
      mc_claim = { mckey: media_item.media_content_key }
      mc_claim[:mcpf] = media_item.profile_key unless media_item.profile_key.nil?
      mc_claim[:is_intro] = media_item.is_intro unless media_item.is_intro.nil?
      mc_claim[:is_seekable] = media_item.is_seekable unless media_item.is_seekable.nil?
      mc_claim[:seekable_end] = media_item.seekable_end unless media_item.seekable_end.nil?
      mc_claim[:disable_playrate] = media_item.disable_playrate unless media_item.disable_playrate.nil?
      payload[:mc].push(mc_claim)
    end

    payload[:cuid] = client_user_id unless client_user_id.nil?
    payload[:awtc] = options[:awt_code] unless options[:awt_code].nil?
    payload[:expt] = Time.now.to_i + (options[:expire_time].nil? ? 7200 : options[:expire_time])

    JWT.encode payload, security_key, 'HS256'
  end


  # web_token_url_by_media_content_key
  #
  # @param [String] media_content_key
  # @param [String|Nil] client_user_id
  # @param [Hash] options
  # @return [String]
  def web_token_url_by_media_content_key(media_content_key:, client_user_id: nil, options: {})
    options[:kind] = 's' if options[:kind].nil?
    mode_path = options[:kind]

    params = {}
    if options[:download].nil?
      params[:autoplay] = 1 unless options[:autoplay].nil?
      params[:mute] = 1 unless options[:mute].nil?
    else
      params[:download] = 1
      params[:force_exclusive_player] = 1
    end

    params[:jwt] = web_token_by_media_content_key(
      media_content_key: media_content_key,
      client_user_id: client_user_id,
      options: options
    )
    params[:custom_key] = @service_account.custom_key

    "#{@scheme}://v.#{@domain}/#{mode_path}?" + URI.encode_www_form(params)
  end

  # web_token_url_by_media_items
  #
  # @param [Array<MediaItem>] media_items
  # @param [String|Nil] client_user_id
  # @param [Hash] options
  # @return [String]
  def web_token_url_by_media_items(media_items:, client_user_id: nil, options: {})
    options[:kind] = 's' if options[:kind].nil?
    mode_path = options[:kind]

    params = {}
    if options[:download].nil?
      params[:autoplay] = 1 unless options[:autoplay].nil?
      params[:mute] = 1 unless options[:mute].nil?
    else
      params[:download] = 1
      params[:force_exclusive_player] = 1
    end

    params[:jwt] = web_token_by_media_items(
      media_items: media_items,
      client_user_id: client_user_id,
      options: options
    )
    params[:custom_key] = @service_account.custom_key

    "#{@scheme}://v.#{@domain}/#{mode_path}?" + URI.encode_www_form(params)
  end
end
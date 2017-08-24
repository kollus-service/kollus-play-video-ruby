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

  # web_token
  #
  # @param [String|Array<MediaItem>] media_content_key
  # @param [String|Nil] client_user_id
  # @param [Hash] options
  # @return [String]
  def web_token(media_content_key:, client_user_id: nil, options: {})
    security_key = options[:security_key].nil? ? @service_account.security_key : options[:security_key]
    payload = { mc:[] }

    if media_content_key.is_a?(Array)
      media_content_key.each do |media_item|
        if media_item.is_a?(MediaItem)
          mc_claim = { mckey: media_item.media_content_key }
          mc_claim[:mcpf] = media_item.media_profile_key unless media_item.media_profile_key.nil?
          mc_claim[:is_intro] = media_item.is_intro unless media_item.is_intro.nil?
          mc_claim[:is_seekable] = media_item.is_seekable unless media_item.is_seekable.nil?
          payload[:mc].push(mc_claim)
        end
      end
    else
      mc_claim = { mckey: media_content_key }
      mc_claim[:mcpf] = options[:media_profile_key] unless options[:media_profile_key].nil?
      mc_claim[:is_intro] = options[:is_intro] unless options[:is_intro].nil?
      mc_claim[:is_seekable] = options[:is_seekable] unless options[:is_seekable].nil?
      payload[:mc].push(mc_claim)
    end

    payload[:cuid] = client_user_id unless client_user_id.nil?
    payload[:awtc] = options[:awt_code] unless options[:awt_code].nil?
    payload[:expt] = Time.now.to_i + (options[:expire_time].nil? ? 7200 : options[:expire_time])

    JWT.encode payload, security_key, 'HS256'
  end

  # web_token_url
  #
  # @param [String|Array<MediaItem>] media_content_key
  # @param [String|Nil] client_user_id
  # @param [String|Nil] custom_key
  # @param [Hash] options
  # @return [String]
  def wet_token_url(media_content_key:, client_user_id: nil, custom_key: nil, options: { kind: 's' })
    mode_path = options[:kind]
    params = { autoplay: 1 }

    params[:jwt] = web_token(
      media_content_key: media_content_key,
      client_user_id: client_user_id,
      options: options
    )
    params[:custom_key] = custom_key.nil? ? @service_account.custom_key : custom_key

    "#{@scheme}://v.#{@domain}/#{mode_path}?" + URI.encode_www_form(params)
  end
end
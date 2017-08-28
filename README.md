# Kollus Play Video By Ruby

Play video by Kollus Web-token : Sample Source

## Requirement

* [ruby](https://www.ruby-lang.org/) : 2.0 above
  * module
    * [sinatra](http://www.sinatrarb.com/) : for smaple code's web framework
    * [sinatra-contrib](http://www.sinatrarb.com/contrib/)
    * [jwt](https://github.com/jwt/ruby-jwt) : for kollus web-token
* [jQuery](https://jquery.com) : 3.2.1
* [Boostrap](https://getbootstrap.com/docs/3.3/) : for smaple code
  
## Installation

```bash
git clone https://github.com/kollus-service/kollus-play-video-ruby
cd kollus-play-video-ruby-ruby

bundle install
```
Copy .config.yml to config.yml and Edit this.

```yaml
kollus:
  domain: [kollus domain]
  version: 0
  service_account:
    key : [service account key]
    api_access_token: [api access token]
    custom_key: [custom key]
    security_key: [security_key]
```

## How to use

```bash
ruby app.rb

...
[2017-08-17 17:00:09] INFO  WEBrick 1.3.1
[2017-08-17 17:00:09] INFO  ruby 2.4.1 (2017-03-22) [x86_64-darwin16]
== Sinatra (v2.0.0) has taken the stage on 4567 for development with backup from WEBrick
[2017-08-17 17:00:09] INFO  WEBrick::HTTPServer#start: pid=34312 port=4567
```

Open browser '[http://localhost:4567](http://localhost:4567)' and You must login.

## Development flow
1. Call local server api for generate 'web-token-url' on browser
   * '/api/web-token-url' in app.rb
   * use web_token in kollus_video_gateway_client.rb
2. Open iframe in instant modal
   * use modal-play-video event in public/js/default.js
3. If you want... Kollus Player can use 'kollus play callback'

### Important code

app.rb
```ruby
post /\/auth\/web-token-url\/(.+)\/(.+)/ do |channel_key, upload_file_key|
  # @type [KollusApiClient] kollus_api_client
  kollus_api_client = settings.kollus_api_client
  # @type [KollusVideoGatewayClient] kollus_video_gateway_client
  kollus_video_gateway_client = settings.kollus_video_gateway_client

  # find media-content-key for sample code
  # use video table on database
  # 
  # @type [MediaContent] media_content
  media_content = kollus_api_client.channel_media_content(
    channel_key: channel_key,
    upload_file_key: upload_file_key
  )

  content_type :json, 'charset' => 'utf-8'
  {
    title: media_content.title,
    web_token_url: kollus_video_gateway_client.wet_token_url(
      media_content_key: media_content.media_content_key,
      client_user_id: session[:client_user_id]
    )
  }.to_json
end
```

lib/kollus_video_gateway_client.rb
```ruby
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
```

public/js/default.js

```javascript
$(document).on('click', 'button[data-action=modal-play-video]', function(e) {
    e.preventDefault();
    e.stopPropagation();

    var self = this,
        channelKey = $(self).attr('data-channel-key'),
        uploadFileKey = $(self).attr('data-upload-file-key'),
        mediaContent;

    $.post('/web-token-url/' + channelKey + '/' + uploadFileKey, function (data) {
        mediaContent = $(
            '<div class="modal-header">\n' +
            '    <button type="button" class="close" data-dismiss="modal">&times;</button>\n' +
            '    <h4 class="modal-title">' + data.title + '</h4>\n' +
            '</div>\n'+
            '<div class="modal-body">\n' +
            '    <div class="embed-responsive embed-responsive-16by9">\n' +
            '        <iframe src="' + data.web_token_url + '" class="embed-responsive-item" allowfullscreen></iframe>\n' +
            '    </div>\n' +
            '</div>\n' +
            '<div class="modal-footer">\n' +
            '    <button type="button" class="btn btn-default" data-dismiss="modal"><span class="fa fa-times"></span> Close</button>\n' +
            '</div>'
        );

        showModal(mediaContent)
    });
});
```

# License

Seee LICENSE for more information
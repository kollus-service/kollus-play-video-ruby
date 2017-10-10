# Kollus Play Video By Ruby

Play or download video by Kollus WebToken : Sample Source

## Requirement

* [ruby](https://www.ruby-lang.org/) : 2.0 above
  * module
    * [sinatra](http://www.sinatrarb.com/) : for sample code's web framework
    * [sinatra-contrib](http://www.sinatrarb.com/contrib/)
    * [jwt](https://github.com/jwt/ruby-jwt) : for kollus web-token
* [jQuery](https://jquery.com) : 3.2.1
* [Boostrap 3](https://getbootstrap.com/docs/3.3/) : for sample code
  
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
  play_options:
    expire_time: 86400 # 1day
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

### Play video

1. Press 'Play' button and call local server api for generate 'web-token-url' on browser
   * '/auth/play-video-url/{channel_key}/{upload_file_key}' in app.rb
2. Generate WebTokenURL
   * use web_token_url_by_media_content_key in lib/client/kollus_video_gateway_client.rb
   * use web_token_by_media_items in lib/client/kollus_video_gateway_client.rb
3. Open iframe + web-token-url in instant modal
   * use modal-play-video event in public/js/default.js
4. If you want... Kollus Player App can use 'kollus play callback'

### Download video

0. You must install Kollus Player App.
1. Press 'Download' button and call local server api for generate 'web-token-url' on browser
   * '/auth/download-video-url/{channel_key}/{upload_file_key}' in app.rb
2. Generate WebTokenURL
   * use web_token_url_by_media_content_key in lib/client/kollus_video_gateway_client.rb
   * use web_token_by_media_items in lib/client/kollus_video_gateway_client.rb
3. Open iframe + web-token-url in instant modal
   * use modal-download-video event in public/js/default.js
4. Call Kollus Player App
5. If you want... Kollus Player App can use 'kollus drm callback'
6. If your platform is mac osx or media is not encrypted, it will be streaming.

### Play video playlist

0. You must install Kollus Player App.
1. Select video.
2. Press 'Play playlist' button and call local server api for generate 'web-token-url' on browser
   * '/auth/play-video-playlist/{channel_key}' in app.rb
3. Generate WebTokenURL
   * use web_token_url_by_media_items in lib/client/kollus_video_gateway_client.rb
   * use web_token_by_media_items in lib/client/kollus_video_gateway_client.rb
4. Call Kollus Player App
5. If your platform is mac osx or more environments, is not working.

### Download Multi video

0. You must install Kollus Player App.
1. Select video.
2. Press 'Download selected' button and call local server api for generate 'web-token-url' on browser
   * '/auth/download-multi-video/{channel_key}' in app.rb
3. Generate WebTokenURL
   * use web_token_url_by_media_items in lib/client/kollus_video_gateway_client.rb
   * use web_token_by_media_items in lib/client/kollus_video_gateway_client.rb
4. Call Kollus Player App

### Important code

#### Common library

lib/client/kollus_video_gateway_client.rb

```ruby
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
```

#### Play video

app.rb
```ruby
post /\/auth\/play-video-url\/(.+)\/(.+)/ do |channel_key, upload_file_key|
  ...

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
```

public/js/default.js

```javascript
$(document).on('click', 'button[data-action=modal-play-video]', function(e) {
  e.preventDefault();

  ...

  $.post('/auth/play-video-url/' + channelKey + '/' + uploadFileKey, function (data) {
    modalContent = $(

      ...

      '        <iframe src="' + data.web_token_url + '" class="embed-responsive-item" allowfullscreen></iframe>\n' +

      ...

    );

    showModal(modalContent)
  });
});
```

#### Download video

app.rb

```ruby
post /\/auth\/download-video-url\/(.+)\/(.+)/ do |channel_key, upload_file_key|
  ...

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
```

public/js/default.js

```javascript
$(document).on('click', 'button[data-action=modal-download-video]', function(e) {
  e.preventDefault();

  ...

  $.post('/auth/download-video-url/' + channelKey + '/' + uploadFileKey, function (data) {
    modalContent = $(

      ...

      '        <iframe src="' + data.web_token_url + '" class="embed-responsive-item" allowfullscreen></iframe>\n' +

      ...

    );

    showModal(modalContent)
  });
});
```

#### Play video by playlist

app.rb

```ruby
post /\/auth\/play-video-playlist\/(.+)/ do |channel_key|
  ...

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
```

public/js/default.js

```javascript
$(document).on('click', 'button[data-action=call-play-video-playlist]', function(e) {
  e.preventDefault();

  ...

  checkedItems.each(function(index, element) {
    uploadFileKey = $(element).val();

    postDatas.selected_media_items.push({
      upload_file_key: uploadFileKey
    });
  });

  $.post('/auth/play-video-playlist/' + channelKey, postDatas, function (data) {
    document.location.href = 'kollus://path?url=' + encodeURIComponent(data.web_token_url);
  });
});
```

#### Download multi video

app.rb

```ruby
post /\/auth\/download-multi-video\/(.+)/ do |channel_key|
  ...

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
```

public/js/default.js

```javascript
$(document).on('click', 'button[data-action=call-download-multi-video]', function(e) {
  e.preventDefault();

  ...

  checkedItems.each(function(index, element) {
    uploadFileKey = $(element).val();

    postDatas.selected_media_items.push({
      upload_file_key: uploadFileKey
    });
  });

  $.post('/auth/download-multi-video/' + channelKey, postDatas, function (data) {
    document.location.href = 'kollus://download?url=' + encodeURIComponent(data.web_token_url);
  });
});
```

# License

Seee LICENSE for more information
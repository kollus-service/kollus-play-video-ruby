require_relative 'container'

# Channel
#
# @attr [String] media_content_key
# @attr [String] profile_key
# @attr [Int] is_intro
# @attr [Int] is_seekable
class MediaItem < Container
  attr_accessor(
      :media_content_key,
      :profile_key,
      :is_intro,
      :is_seekable
  )
end
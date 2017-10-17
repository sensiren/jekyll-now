# A Liquid tag for Jekyll sites that allows embedding Instagrams
# by: Luke Karrys
#
# Example usage: {% instagram media_id %}

require 'instagram'
require 'json'

module Jekyll
  class InstagramTag < Liquid::Tag
    def initialize(tag_name, markup, token)
      super
      access_token_file = File.expand_path "../.instagram/access_token", File.dirname(__FILE__)
      @access_token     = File.open(access_token_file).gets
      @image_res        = "standard_resolution"
      @markup           = markup
      @cache_folder     = File.expand_path "../.instagram-cache", File.dirname(__FILE__)
      FileUtils.mkdir_p @cache_folder
    end

    def render(context)
      split_markup = @markup.split
      media_id = split_markup[0].strip
      no_caption = split_markup.include?('no_caption')
      id = @markup.strip
      media = get_cached_media(media_id) || get_media(media_id)
      return gen_html_output(JSON.parse(media), no_caption)
    end

    def gen_html_output(media, no_caption)

      loc_name, lat, lon = nil, nil, nil
      id              = media["id"]
      link            = media["link"]
      src             = media["images"][@image_res]["url"]
      image_w         = media["images"][@image_res]["width"]
      image_h         = media["images"][@image_res]["height"]
      location        = media["location"]
      filter          = media["filter"]
      caption         = media["caption"]
      created         = Time.at(Integer(media["created_time"])).strftime("%I:%M%p %B %e, %Y")
      title           = caption ? caption["text"] : "Untitled Instagram"
      output = "<p class='instagram'><a href='#{link}'><img src='#{src}' alt='#{title}' /></a></p>"
      if !no_caption
        output += "<p class='caption'>#{title}</p>"
      end
      return output
    end

    def get_cache_file_for(id)
      File.join @cache_folder, "#{id}.cache"
    end

    def cache(id, data)
      cache_file = get_cache_file_for id
      File.open(cache_file, "w") do |io|
        io.write data
      end
    end

    def get_media(id)
      client = Instagram.client(:access_token => @access_token)
      data = client.media_shortcode(id).to_json
      cache id, data unless @cache_disabled
      data
    end

    def get_cached_media(id)
      cache_file = get_cache_file_for id
      File.read cache_file if File.exist? cache_file
    end
  end
end

Liquid::Template.register_tag("instagram", Jekyll::InstagramTag)
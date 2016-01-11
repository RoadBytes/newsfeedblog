class NewsItem
  attr_accessor :news_object
  def initialize(object)
    @news_object = object
  end

  def object_text
    if self.tweet?
      news_object.text
    else
      news_object.body
    end
  end

  def type
    if tweet?
      "Tweet"
    else
      "Blog Post"
    end
  end

  def tweet?
    self.class == Twitter::Tweet
  end

  def class
    news_object.class
  end

  def created_at
    news_object.created_at.to_datetime.utc.to_formatted_s(:long)
  end
end

class NewsBundle < NewsItem
  def self.get_objects
    if query_stale?
      @objects =  tweet_objects
      @objects += Post.last(6)
    end

    sorted_and_mapped
  end

  def self.query_refreshed_at
    @query_refreshed_at
  end

  def self.query_stale?
    # expire @query every five minutes
    @query_refreshed_at ||= Time.now
    @objects.blank? || (Time.now - @query_refreshed_at > 5.minutes)
  end

  def self.tweet_objects
    tweets = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET_KEY']
      config.access_token        = ENV['TWITTER_OAUTH_TOKEN']
      config.access_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
    end

    tweets.user_timeline("Jason_Data")
  end

  def self.sorted_and_mapped
    @objects.map do |object|
      NewsItem.new(object)
    end.sort_by {|obj| obj.created_at }.reverse[0..6]
  end
end

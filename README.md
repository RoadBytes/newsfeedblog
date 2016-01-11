# My first Interview!

After my first developer interview, I had an "inspiration" to make a toy blog app to see if I could implement a *News Feed* feature where the News Feed would display the last six "things" I did.

* [Here's my finished coding spike](https://newsfeed-blog.herokuapp.com/): https://newsfeed-blog.herokuapp.com/

* [Repo is here](https://github.com/RoadBytes/newsfeedblog): https://github.com/RoadBytes/newsfeedblog

### Here are a few specs I think I remember:
* The feed could include blog posts, or tweets, or other media I could have out there.
* It would be on the home page on the bottom
* It would consist of the latest things I've posted

To save time I stole bits of [this guys implementation (Leonard Garvey)](https://twitter.com/lgarvey) of a [Rails Blog in 15 minutes app.](https://reinteractive.net/posts/32-ruby-on-rails-3-2-blog-in-15-minutes-step-by-step) 

Then, I had to do some sleuthing for a Twitter Rails gem.  I found [this](https://github.com/sferik/twitter) and it was super cool to use.

### Man!  I learned a whole lot just playing with this application.
* First off, Twitter API is pretty cool and I pulled the tweets from an app I made on my Twitter home page.
  * you can make your own twitter app at [https://apps.twitter.com/](https://apps.twitter.com/)
* I decided to just work with Tweets and Posts to have an easy code spike and hope to finish the implementation sooner than later.
* I first thought of having Polymorphic Association with different `NewFeed` objects, but since I only the last 6 things I did, I figured it'd be easier to have something that wasn't persistant.
* This was one of the first non-ActiveRecord backed models I've made for a Rails App.
  * I made a `NewsBundle` model that would instantiate `NewItem`s and pull off the `created_at`, `object_text`, and `type` information
  * it was much easier working with two types of objects, `Posts` and `Tweets` but adding another type of object would be interesting
  * to limit the API querying, I had the `NewsBundle` only update if it wasn't ever called or if was older than 5 minutes
  * Thanks [Milan](https://twitter.com/milandobrota) for the help

~~~
  def self.query_stale?
    # expire @query every five minutes
    @query_refreshed_at ||= Time.now
    @objects.blank? || (Time.now - @query_refreshed_at > 5.minutes)
  end
~~~

### Things to think of for next steps
* I haven't added testing so I'd consider this more of a spike since I'm not using this for production
* I don't have much experience testing API's, I wonder how the TDD process would look like


### Actual Code (for your convenience)

## Here is the main bread and butter of the NewsBundle

* I'm still needing to get over terms... I like `NewsBundle` better than `NewsFeed`, but I need to stick to one and own it eventually.
* I probably need to move the `NewsItem` out, but I didn't really mind it since it's a code spike (haha, did I say code spike enough?)
  * I've never hard coded a class inside a class like that (I'm sure that's a noob thing [insert tounge face])
* It's weird, but the `NewsBundle` is really the Enumerable version of `NewsItem`... I'm sure there's an easy way to arrange or set up the model.

~~~
# file at: app/models/news_bundle.rb
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
~~~

## The controller side of things

I called the `NewsBundle.get_objects` from the 'posts#index' action

~~~
# file at: app/controllers/posts_controller.rb

class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  # GET /posts
  # GET /posts.json
  def index
    @posts        = Post.all
    @news_objects = NewsBundle.get_objects
    @query_time   = NewsBundle.query_refreshed_at
  end

  # template stuff omitted

end
~~~

## And finally the view

* the query_time was just a way for me to see that the API was being queried properly, but then I liked it.
* I actually started here, with the ideal methods I wanted to have and worked backwards

~~~
# file at: app/views/posts/index.html.erb

  # template stuff omitted AGAIN! Muhaha

<h1>News Feed</h1>

<h3>Queried Fresh At: <%= @query_time %></h3>

<table>
  <thead>
    <tr>
      <th>
        <%= "Date and Time" %>
      </th>
      <th>
        <%= "Type of Article" %>
      </th>
      <th>
        <%= "Text" %>
      </th>
    </tr>
  </thead>

  <%- @news_objects.each do |news_object| %>
    <tbody>
      <tr>
        <td>
          <%= news_object.created_at %>
        </td>
        <td>
          <%= news_object.type %>
        </td>
        <td>
          <%= news_object.object_text %>
        </td>
      </tr>
    </tbody>
  <% end %>
</table>
~~~

### In conlusion, I'm going to bed!

All in all, this was a great experience and I've learned a lot from taking something from idea to implementation.  Getting my first interview was a great experience and I'm sure there will be other opportunities for me to stretch myself and show progress.  If you have any questions or comments, leave one on my blog site: [roadbytes.me](http://roadbytes.me) or email me at:

Jason.Data@roadbytes.me


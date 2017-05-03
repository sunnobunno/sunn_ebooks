require 'twitter_ebooks'

class UserInfo
  attr_reader :username

  # @return [Integer] how many times we can pester this user unprompted
  attr_accessor :pesters_left

  # @param username [String]
  def initialize(username)
    @username = username
    @pesters_left = 1
  end
end

# This is an example bot definition with event handlers commented out
# You can define and instantiate as many bots as you like

class MyBot < Ebooks::Bot
  attr_accessor :original, :model, :model_path
  # Configuration here applies to all MyBots
  def configure
    # Consumer details come from registering an app at https://dev.twitter.com/
    # Once you have consumer details, use "ebooks auth" for new access tokens
    self.consumer_key = 't9g6TgrUYsZ4R5aeArsM2C36G' # Your app consumer key
    self.consumer_secret = 'olto6fNhfZz0CZwtx4uaFFpoyW88KG4LZnuaMFtWkvhgWq3897' # Your app consumer secret

    # Users to block instead of interacting with
    self.blacklist = ['']

    # Range in seconds to randomize delay when bot.delay is called
    self.delay_range = 1..6
	
	@userinfo = {}
  end
  
  model = Ebooks::Model.load("model/sunnobunno.model")
  
  def top100; @top100 ||= model.keywords.take(100); end
  def top20; @top20 ||= model.keywords.take(20); end

  def on_startup
	model = Ebooks::Model.load("model/sunnobunno.model")
	
    scheduler.every '30m' do
      # Tweet something every 10 minutes
      # See https://github.com/jmettraux/rufus-scheduler
      tweet(model.make_statement)
    end
  end

  def on_message(dm)
    model = Ebooks::Model.load("model/sunnobunno.model")
    # Reply to a DM
    # reply(dm, "secret secrets")
	delay do
      reply(dm, model.make_response(dm.text))
	end
  end

  def on_follow(user)
    # Follow a user back
    follow(user.screen_name)
  end

  def on_mention(tweet)
    model = Ebooks::Model.load("model/sunnobunno.model")
    # Reply to a mention
    # reply(tweet, "oh hullo")
	userinfo(tweet.user.screen_name).pesters_left += 1
	
    delay do
      reply(tweet, model.make_response(meta(tweet).mentionless, meta(tweet).limit))
    end
  end

  def on_timeline(tweet)
    
  end
  
  # Find information we've collected about a user
  # @param username [String]
  # @return [Ebooks::UserInfo]
  def userinfo(username)
    @userinfo[username] ||= UserInfo.new(username)
  end

  # Check if we're allowed to send unprompted tweets to a user
  # @param username [String]
  # @return [Boolean]
  def can_pester?(username)
    userinfo(username).pesters_left > 0
  end

  # Only follow our original user or people who are following our original user
  # @param user [Twitter::User]
  def can_follow?(username)
    @original.nil? || username.casecmp(@original) == 0 || twitter.friendship?(username, @original)
  end

  def on_favorite(user, tweet)
    # Follow user who just favorited bot's tweet
	if can_follow?(user.screen_name)
      follow(user.screen_name)
    else
      log "Not following @#{user.screen_name}"
    end
  end

  def on_retweet(tweet)
    # Follow user who just retweeted bot's tweet
    # follow(tweet.user.screen_name)
	if can_follow?(user.screen_name)
      follow(user.screen_name)
    else
      log "Not following @#{user.screen_name}"
    end
  end
end

# Make a MyBot and attach it to an account
MyBot.new("sunn_ebooks") do |bot|
  bot.access_token = "853478502024216584-yO1SoKJthgLWmZRnYuw3Or0GFOs1FnJ" # Token connecting the app to this account
  bot.access_token_secret = "uQTiDTJbUvT4Z7rWWDdxtaEM0JwKULTveHhPic2H9Fr4I" # Secret connecting the app to this account
end

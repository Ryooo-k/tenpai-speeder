Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer, fields: %i[ name ] if Rails.env.development?
  provider :twitter, ENV['TWITTER_API_KEY'],  ENV['TWITTER_API_SECRET']
end

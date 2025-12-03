Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer unless Rails.env.production?

  twitter_options = if Rails.env.production?
                      { callback_url: 'https://tenpai-speeder.com/auth/twitter2/callback' }
                    else
                      {}
                    end

  provider :twitter2,
            ENV.fetch('TWITTER_CLIENT_ID', 'test'),
            ENV.fetch('TWITTER_CLIENT_SECRET', 'test'),
            twitter_options
end

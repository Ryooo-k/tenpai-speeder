Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer unless Rails.env.production?

  provider :google_oauth2,
            ENV.fetch('GOOGLE_CLIENT_ID', 'test'),
            ENV.fetch('GOOGLE_CLIENT_SECRET', 'test'),
            { scope: 'email, profile' }
end

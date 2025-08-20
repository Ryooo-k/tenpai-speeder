# frozen_string_literal: true

source 'https://rubygems.org'

gem 'rails', '~> 8.0.2'
gem 'propshaft'
gem 'sqlite3', '>= 2.1'
gem 'puma', '>= 5.0'
gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'jbuilder'
gem 'tzinfo-data', platforms: %i[ windows jruby ]
gem 'solid_cache'
gem 'solid_queue'
gem 'solid_cable'
gem 'bootsnap', require: false
gem 'kamal', require: false
gem 'thruster', require: false
gem 'tailwindcss-rails', '~> 4.3'
gem 'inline_svg'
gem 'omniauth'
gem "omniauth-rails_csrf_protection"
gem 'omniauth-twitter'
gem 'dotenv-rails'

group :development, :test do
  gem 'debug', platforms: %i[ mri windows ], require: 'debug/prelude'
  gem 'brakeman', '~> 7.1.0', require: false
  gem 'rubocop-rails-omakase', require: false
end

group :development do
  gem 'web-console'
  gem 'erb_lint', require: false
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
end

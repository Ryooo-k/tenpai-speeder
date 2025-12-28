# frozen_string_literal: true

require 'test_helper'

Capybara.default_max_wait_time = 8

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  OmniAuth.config.test_mode = true

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  private

    def login_as_guest
      visit root_path
      click_button '登録せずに利用開始'
      assert_text 'ログインしました'
    end

    def login_with_google(user)
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: 'google_oauth2',
        uid: user.uid,
        info: { name: user.name, email: user.email }
      )

      visit root_path
      click_button 'Googleでログインする'
      assert_text 'ログインしました'
    end
end

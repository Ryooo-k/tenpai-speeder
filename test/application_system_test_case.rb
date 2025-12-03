# frozen_string_literal: true

require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  OmniAuth.config.test_mode = true

  teardown do
    OmniAuth.config.mock_auth[:twitter2] = nil
  end

  private

    def login_as_guest
      visit root_path
      click_button '登録せずに利用開始'
      assert_text 'ログインしました'
    end

    def login_with_twitter(user)
      OmniAuth.config.mock_auth[:twitter2] = OmniAuth::AuthHash.new(
        provider: 'twitter2',
        uid: user.uid,
        info: { name: user.name }
      )

      visit root_path
      click_button 'X（旧Twitter）でログイン'
      assert_text 'ログインしました'
    end
end

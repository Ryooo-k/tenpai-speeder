# frozen_string_literal: true

require 'application_system_test_case'

class LoginTest < ApplicationSystemTestCase
  test 'guest login' do
    visit root_path
    click_button '登録せずに利用開始'
    assert_text 'ログインしました(guest-'
  end

  test 'login with google' do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: '1234',
      info: { name: 'ryo', email: 'ryo@example.com' }
    )
    visit root_path
    click_button 'Googleでログインする'
    assert_text 'ログインしました'
  end

  test 'failure login without name' do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: '1234',
      info: { name: '' }
    )
    visit root_path
    click_button 'Googleでログインする'
    assert_text 'ユーザー認証に失敗しました'
  end
end

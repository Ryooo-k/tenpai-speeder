# frozen_string_literal: true

require 'application_system_test_case'

class LoginTest < ApplicationSystemTestCase

  test 'guest login' do
    visit root_path
    click_button '登録せずに利用開始'
    assert_text 'ログインしました(guest-'
  end

  test 'login with twitter' do
    OmniAuth.config.mock_auth[:twitter] = OmniAuth::AuthHash.new(
      provider: 'twitter',
      uid: '1234',
      info: { name: 'ryo' }
    )
    visit root_path
    click_button 'X（旧Twitter）でログイン'
    assert_text 'ログインしました'
  end

  test 'failure login without name' do
    OmniAuth.config.mock_auth[:twitter] = OmniAuth::AuthHash.new(
      provider: 'twitter',
      uid: '1234',
      info: { name: '' }
    )
    visit root_path
    click_button 'X（旧Twitter）でログイン'
    assert_text 'ユーザー認証に失敗しました'
  end
end

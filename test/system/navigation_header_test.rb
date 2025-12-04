# frozen_string_literal: true

require 'application_system_test_case'

class NavigationHeaderTest < ApplicationSystemTestCase
  test 'hamburger menu is hidden on welcome page' do
    visit root_path
    assert_no_selector 'button[aria-label="メニューを開く"]'
  end

  test 'logged-in user opens hamburger menu and moves to favorites page' do
    login_with_google users(:ryo)

    find('button[aria-label="メニューを開く"]').click
    dropdown = find('div[data-dropdown-target="menu"]', text: 'お気に入り一覧')

    within(dropdown) do
      click_link 'お気に入り一覧'
    end
    assert_current_path favorites_path
    assert_selector 'h1', text: 'お気に入り一覧'
  end

  test 'user can logout from hamburger menu and return to welcome page' do
    login_with_google users(:ryo)
    find('button[aria-label="メニューを開く"]').click

    accept_confirm 'ログアウトしますか？' do
      click_link 'ログアウト'
    end

    assert_current_path root_path
    assert_text 'ログアウトしました'
    assert_no_selector 'button[aria-label="メニューを開く"]'
  end

  test 'user can navigate back home from hamburger menu' do
    login_with_google users(:ryo)
    visit favorites_path

    find('button[aria-label="メニューを開く"]').click
    dropdown = find('div[data-dropdown-target="menu"]', text: 'ホームに戻る')

    within(dropdown) do
      click_link 'ホームに戻る'
    end

    assert_current_path home_path
  end

  test 'clicking the logo navigates to home when current page is not root' do
    login_with_google users(:ryo)
    visit favorites_path

    find("header a[data-test-id='logo']").click

    assert_current_path home_path
  end

  test 'clicking the logo navigates to root when current page is root' do
    visit root_path

    find("header a[data-test-id='logo']").click

    assert_current_path root_path
  end
end

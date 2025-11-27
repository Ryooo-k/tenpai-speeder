# frozen_string_literal: true

require 'application_system_test_case'

class FavoritesTest < ApplicationSystemTestCase
  setup do
    @member = users(:ryo)
    @game = games(:tonnan)
    @member.favorites.destroy_all
  end

  test 'user adds favorite from game play page and sees it on favorites gage' do
    login_with_twitter @member

    visit game_play_path(@game)
    click_button 'お気に入りに追加'
    assert_button 'お気に入り解除'

    visit favorites_path
    assert_selector 'h1', text: 'お気に入り一覧'
    assert_text @game.game_mode.name
  end

  test 'user removes favorites page and empty state appears' do
    @member.favorites.create!(game: @game)

    login_with_twitter @member

    visit favorites_path
    assert_text @game.game_mode.name

    accept_confirm '削除してもよろしいですか？' do
      click_button 'お気に入り解除'
    end

    assert_text 'お気に入りはまだありません'
  end

  test 'guest user can not access favorites page' do
    login_as_guest

    visit favorites_path
    assert_current_path root_path
    assert_text 'SNSログインが必要です'
  end

  test 'user toggles favorite on play page without reload' do
    login_with_twitter @member
    visit game_play_path(@game)

    assert_button 'お気に入りに追加'
    click_button 'お気に入りに追加'
    assert_button 'お気に入り解除'

    click_button 'お気に入り解除'
    assert_button 'お気に入りに追加'
  end
end

# frozen_string_literal: true

require 'application_system_test_case'

class IdorGamesAccessTest < ApplicationSystemTestCase
  def create_game_as_guest
    login_as_guest
    visit home_path
    find("button[aria-label*='1局戦']").click
    assert_current_path(%r{/games/(\d+)/play})
    URI.parse(page.current_url).path[%r{\A/games/(\d+)/play\z}, 1]
  end

  test 'owner can view their game; other users see 404' do
    game_id = nil

    using_session(:owner) do
      game_id = create_game_as_guest
    end

    using_session(:intruder) do
      login_as_guest
      visit "/games/#{game_id}/play"
      assert_current_path(home_path)
      assert_text 'ゲームが見つかりません。'
    end

    using_session(:owner) do
      visit "/games/#{game_id}/play"
      assert_current_path(%r{/games/#{game_id}/play})
    end
  end
end

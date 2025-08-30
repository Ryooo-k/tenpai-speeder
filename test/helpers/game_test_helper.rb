# frozen_string_literal: true

module GameTestHelper
  def find_game_from_url
    path = URI.parse(response.location).path
    game_id = path[%r{\A/games/(\d+)/play\z}, 1].to_i
    Game.find(game_id)
  end

  def set_user_turn(game)
    game.advance_current_player! while game.current_player.ai?
  end

  def set_opponent_turn(game)
    game.advance_current_player! unless game.current_player.ai?
  end
end

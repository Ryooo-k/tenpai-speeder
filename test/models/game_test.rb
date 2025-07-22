# frozen_string_literal: true

require 'test_helper'

class GameTest < ActiveSupport::TestCase
  test 'destroying game should also destroy players' do
    game = games(:tonpuu)
    assert_difference('Player.count', -game.players.count) do
      game.destroy
    end
  end

  test 'destroying game should also destroy results' do
    game = games(:tonpuu)
    assert_difference('Result.count', -game.results.count) do
      game.destroy
    end
  end

  test 'destroying game should also destroy favorites' do
    game = games(:tonpuu)
    assert_difference('Favorite.count', -game.favorites.count) do
      game.destroy
    end
  end

  test 'destroying game should also destroy rounds' do
    game = games(:tonpuu)
    assert_difference('Round.count', -game.rounds.count) do
      game.destroy
    end
  end

  test 'destroying game should also destroy tiles' do
    game = games(:tonpuu)
    assert_difference('Tile.count', -game.tiles.count) do
      game.destroy
    end
  end

  test 'is valid with game_mode and rule' do
    game_mode = game_modes(:match)
    rule = rules(:tonpuu_with_aka_dora)
    game = Game.new(game_mode:, rule:)
    assert game.valid?
  end

  test 'is invalid without game_mode' do
    rule = rules(:tonpuu_with_aka_dora)
    game = Game.new(rule:)
    assert game.invalid?
  end

  test 'is invalid without rule' do
    game_mode = game_modes(:match)
    game = Game.new(game_mode:)
    assert game.invalid?
  end
end

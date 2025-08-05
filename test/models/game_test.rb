# frozen_string_literal: true

require 'test_helper'

class GameTest < ActiveSupport::TestCase
  def setup
    @game = games(:tonpuu)
  end

  test 'destroying game should also destroy players' do
    assert_difference('Player.count', -@game.players.count) do
      @game.destroy
    end
  end

  test 'destroying game should also destroy results' do
    assert_difference('Result.count', -@game.results.count) do
      @game.destroy
    end
  end

  test 'destroying game should also destroy favorites' do
    assert_difference('Favorite.count', -@game.favorites.count) do
      @game.destroy
    end
  end

  test 'destroying game should also destroy rounds' do
    assert_difference('Round.count', -@game.rounds.count) do
      @game.destroy
    end
  end

  test 'destroying game should also destroy tiles' do
    assert_difference('Tile.count', -@game.tiles.count) do
      @game.destroy
    end
  end

  test 'is valid with game_mode' do
    game_mode = game_modes(:tonpuu_mode)
    game = Game.new(game_mode:)
    assert game.valid?
  end

  test 'is invalid without game_mode' do
    game = Game.new
    assert game.invalid?
  end

  test 'creates first round and 136 tiles when after_create calls setup_initial_game' do
    game = Game.new(game_mode: game_modes(:tonpuu_mode))
    assert_equal 0, game.rounds.count
    assert_equal 0, game.tiles.count

    game.save
    assert_equal 1, game.rounds.count
    assert_equal 136, game.tiles.count

    tallied_tile_suits = game.tiles.map { |tile| tile.suit }.tally
    tallied_tile_suits.each do |suit, count|
      expected_suit_count = suit == 'zihai' ? 28 : 36
      assert_equal expected_suit_count, count
    end

    tallied_tile_names = game.tiles.map { |tile| tile.name }.tally
    assert tallied_tile_names.values.all? { |count| count == 4 }
  end

  test '#setup_players creates 4 players and game_record' do
    user = users(:ryo)
    ai = ais(:menzen_tenpai_speeder)
    game = Game.new(game_mode: game_modes(:tonpuu_mode))
    assert_equal 0, game.players.count

    game.save
    game.setup_players(user, ai)
    assert_equal 4, game.players.count
    game.players.each do |player|
      assert_equal 1, player.game_records.count
    end

    user_players = game.players.where(user_id: user.id)
    assert_equal 1, user_players.count

    ai_players = game.players.where(ai_id: ai.id)
    assert_equal 3, ai_players.count
  end

  test 'create aka_dora tiles with correct aka flag' do
    game = Game.new(game_mode: game_modes(:tonpuu_mode))
    game.save

    game.tiles.each do |tile|
      aka_dora_flag = Game::AKA_DORA_TILE_CODES.include?(tile.code) && tile.kind.zero?
      assert_equal aka_dora_flag, tile.aka?
    end
  end

  test '#deal_initial_hands creates 13 hands for each player' do
    game = games(:tonpuu)
    game.players.each do |player|
      assert_equal 0, player.hands.count
    end

    game.deal_initial_hands
    game.players.ordered.each do |player|
      assert_equal 13, player.hands.count
    end
  end
end

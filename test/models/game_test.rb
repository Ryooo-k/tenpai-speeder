# frozen_string_literal: true

require 'test_helper'

class GameTest < ActiveSupport::TestCase
  def setup
    @game = games(:tonpuu)
    @user = users(:ryo)
    @ai = ais(:menzen_tenpai_speeder)
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

  test 'current_seat_number default to 0' do
    assert_equal 0, @game.current_seat_number
  end

  test 'creates first round and 136 tiles when after_create calls create_tiles_and_round' do
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
    game = Game.new(game_mode: game_modes(:tonpuu_mode))
    assert_equal 0, game.players.count

    game.save
    game.setup_players(@user, @ai)
    assert_equal 4, game.players.count
    game.players.each do |player|
      assert_equal 1, player.game_records.count
    end

    user_players = game.players.where(user_id: @user.id)
    assert_equal 1, user_players.count

    ai_players = game.players.where(ai_id: @ai.id)
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
    @game.players.each do |player|
      assert_equal 0, player.hands.count
    end
    assert_equal 0, @game.draw_count

    @game.deal_initial_hands
    @game.players.ordered.each do |player|
      assert_equal 13, player.hands.count
    end
    assert_equal 52, @game.draw_count
  end

  test '#user_player' do
    game = Game.new(game_mode: game_modes(:tonpuu_mode))
    game.save
    game.setup_players(@user, @ai)
    assert_equal @user.id, game.user_player.user_id
  end

  test '#opponents' do
    game = Game.new(game_mode: game_modes(:tonpuu_mode))
    game.save
    game.setup_players(@user, @ai)
    game.opponents.each do |opponent|
      assert_equal @ai.id, opponent.ai_id
    end
  end

  test '#current_player' do
    assert_equal @game.current_seat_number, @game.current_player.seat_order
  end

  test '#advance_current_player!' do
    before_current_player = @game.current_player
    @game.advance_current_player!
    assert_not_equal before_current_player, @game.current_player
    assert_equal @game.current_seat_number, @game.current_player.seat_order
  end

  test '#draw_for_current_player' do
    before_hands = @game.current_player.hands
    before_draw_count = @game.draw_count
    @game.draw_for_current_player
    assert_equal before_hands.count + 1, @game.current_player.hands.count
    assert_equal before_draw_count + 1, @game.draw_count
  end

  test '#discard_for_current_player' do
    @game.draw_for_current_player
    before_hands = @game.current_player.hands
    before_rivers = @game.current_player.rivers
    target_tile = before_hands.last

    @game.discard_for_current_player(target_tile.id)
    assert_not_equal before_hands, @game.current_player.hands
    assert_not_includes @game.current_player.hands, target_tile
    assert_not_equal before_rivers, @game.current_player.rivers
    assert_includes @game.current_player.rivers, target_tile
  end
end

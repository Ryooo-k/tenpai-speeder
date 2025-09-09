# frozen_string_literal: true

require 'test_helper'
require 'helpers/game_test_helper'

class GameTest < ActiveSupport::TestCase
  include GameTestHelper

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

  test 'current_step_number default to 0' do
    assert_equal 0, @game.current_step_number
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
    assert @game.user_player.user_id.present?
    assert_not @game.user_player.ai_id.present?
  end

  test '#opponents' do
    @game.opponents.each do |opponent|
      assert opponent.ai_id.present?
      assert_not opponent.user_id.present?
    end
  end

  test '#current_player returns player at current seat' do
    expected = @game.players.find_by!(seat_order: @game.current_seat_number)
    assert_equal expected, @game.current_player
  end

  test '#advance_current_player! changes current_player to next_player' do
    ordered_players =  @game.players.ordered
    ordered_players.each_with_index do |player, seat_number|
      assert_equal player, @game.current_player

      @game.advance_current_player!
      next_seat_number = (seat_number + 1) % ordered_players.count
      assert_equal ordered_players[next_seat_number], @game.current_player
    end
  end

  test '#advance_to_player! changes current_player to target_player' do
    @game.players.each do |player|
      @game.advance_to_player!(player)
      assert_equal player, @game.current_player
    end
  end

  test '#draw_for_current_player increments current_player hand count' do
    before_hand_count = @game.current_player.hands.count
    @game.draw_for_current_player
    assert_equal before_hand_count + 1, @game.current_player.hands.count
  end

  test '#draw_for_current_player increments draw_count' do
    before_draw_count = @game.draw_count
    @game.draw_for_current_player
    assert_equal before_draw_count + 1, @game.draw_count
  end

  test '#draw_for_current_player increments current_step_number and creates new step' do
    before_step_number = @game.current_step_number
    @game.draw_for_current_player
    assert_equal before_step_number + 1, @game.current_step_number
  end

  test '#discard_for_current_player moves tile from hands to rivers' do
    manzu_1 = tiles(:first_manzu_1)
    manzu_2 = tiles(:first_manzu_2)
    hand_1 = @game.current_player.current_state.hands.create!(tile: manzu_1)
    @game.current_player.current_state.hands.create!(tile: manzu_2)
    assert_equal [ manzu_1, manzu_2 ], @game.current_player.hands.map(&:tile)
    assert_equal [], @game.current_player.rivers

    @game.discard_for_current_player(hand_1.id)
    assert_equal [ manzu_2 ], @game.current_player.hands.map(&:tile)
    assert_equal [ manzu_1 ], @game.current_player.rivers.map(&:tile)
  end

  test '#discard_for_current_player increments current_step_number and creates new step' do
    hand = @game.current_player.current_state.hands.create!(tile: tiles(:first_manzu_1))
    before_step_number = @game.current_step_number
    @game.discard_for_current_player(hand.id)
    assert_equal before_step_number + 1, @game.current_step_number
  end

  test '#current_round_name' do
    current_round = @game.rounds.order(:number).last
    current_round.update!(number: 0)
    assert_equal '東一局', @game.current_round_name

    current_round.update!(number: 1)
    assert_equal '東二局', @game.current_round_name

    current_round.update!(number: 4)
    assert_equal '南一局', @game.current_round_name
  end

  test '#current_honba_name' do
    current_honba = @game.rounds.order(:number).last.current_honba
    current_honba.update!(number: 0)
    assert_equal '〇本場', @game.current_honba_name

    current_honba.update!(number: 1)
    assert_equal '一本場', @game.current_honba_name

    current_honba.update!(number: 4)
    assert_equal '四本場', @game.current_honba_name
  end

  test '#remaining_tile_count' do
    current_honba = @game.rounds.order(:number).last.current_honba
    current_honba.update!(draw_count: 0)
    current_honba.update!(kan_count: 0)
    assert_equal 122, @game.remaining_tile_count

    current_honba.update!(draw_count: 10)
    assert_equal 112, @game.remaining_tile_count

    current_honba.update!(kan_count: 2)
    assert_equal 110, @game.remaining_tile_count
  end

  test '#dora_indicator_tiles' do
    current_honba = @game.rounds.order(:number).last.current_honba
    current_honba.update!(kan_count: 0)
    assert_equal [ Tile, NilClass, NilClass, NilClass, NilClass ], @game.dora_indicator_tiles.map(&:class)

    current_honba.update!(kan_count: 1)
    assert_equal [ Tile, Tile, NilClass, NilClass, NilClass ], @game.dora_indicator_tiles.map(&:class)

    current_honba.update!(kan_count: 2)
    assert_equal [ Tile, Tile, Tile, NilClass, NilClass ], @game.dora_indicator_tiles.map(&:class)

    current_honba.update!(kan_count: 3)
    assert_equal [ Tile, Tile, Tile, Tile, NilClass ], @game.dora_indicator_tiles.map(&:class)

    current_honba.update!(kan_count: 4)
    assert_equal [ Tile, Tile, Tile, Tile, Tile ], @game.dora_indicator_tiles.map(&:class)
  end

  test '#host_player' do
    expected = @game.rounds.order(:number).last.host_seat_number
    assert_equal expected, @game.host_player.seat_order
  end

  test '#riichi_stick_count' do
    current_honba = @game.rounds.order(:number).last.current_honba
    current_honba.update!(riichi_stick_count: 0)
    assert_equal 0, @game.riichi_stick_count

    current_honba.update!(riichi_stick_count: 1)
    assert_equal 1, @game.riichi_stick_count
  end

  test '#apply_furo moves tile from hands to melds' do
    set_opponent_turn(@game)
    manzu_1 = tiles(:first_manzu_1)
    manzu_2 = tiles(:first_manzu_2)
    haku = tiles(:first_haku)
    discarded_tile = tiles(:first_manzu_3)

    @game.current_player.current_state.rivers.create!(tile: discarded_tile, tsumogiri: false)
    hand_1 = @game.user_player.current_state.hands.create!(tile: manzu_1)
    hand_2 = @game.user_player.current_state.hands.create!(tile: manzu_2)
    @game.user_player.current_state.hands.create!(tile: haku)
    assert_equal [ manzu_1, manzu_2, haku ], @game.user_player.hands.map(&:tile)
    assert_equal [], @game.user_player.melds.map(&:tile)

    furo_ids = [ hand_1.id, hand_2.id ]
    @game.apply_furo(:chi, furo_ids, discarded_tile.id)
    assert_equal [ haku ], @game.user_player.hands.map(&:tile)
    assert_equal [ manzu_1, manzu_2, discarded_tile ], @game.user_player.melds.map(&:tile)
  end

  test '#apply_furo increments current_step_number and creates new step' do
    set_opponent_turn(@game)
    before_step_number = @game.current_step_number
    hand_1 = @game.user_player.current_state.hands.create!(tile: tiles(:first_manzu_1))
    hand_2 = @game.user_player.current_state.hands.create!(tile: tiles(:first_manzu_2))
    furo_ids = [ hand_1.id, hand_2.id ]
    @game.apply_furo(:chi, furo_ids, tiles(:first_manzu_3).id)
    assert_equal before_step_number + 1, @game.current_step_number
  end
end

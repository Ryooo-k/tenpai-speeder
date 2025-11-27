# frozen_string_literal: true

require 'test_helper'

class GameTest < ActiveSupport::TestCase
  include GameTestHelper

  def setup
    @game = games(:tonnan)
    @user = users(:ryo)
    @ai = ais('v0.1')
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
    game_mode = game_modes(:match)
    game = Game.new(game_mode:)
    assert game.valid?
  end

  test 'is invalid without game_mode' do
    game = Game.new
    assert game.invalid?
  end

  test 'current_seat_number default to 0' do
    game_mode = game_modes(:match)
    game = Game.new(game_mode:)
    assert_equal 0, game.current_seat_number
  end

  test 'current_step_number default to 0' do
    game_mode = game_modes(:match)
    game = Game.new(game_mode:)
    assert_equal 0, game.current_step_number
  end

  test 'creates first round and 136 tiles when after_create calls create_tiles_and_round' do
    game = Game.new(game_mode: game_modes(:match))
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
    game = Game.new(game_mode: game_modes(:match))
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
    game = Game.new(game_mode: game_modes(:match))
    game.save

    game.tiles.each do |tile|
      aka_dora_flag = Game::AKA_DORA_TILE_CODES.include?(tile.code) && tile.kind.zero?
      assert_equal aka_dora_flag, tile.aka?
    end
  end

  test '#apply_game_mode assign 25_000 score and first round when game mode is not final_found' do
    game = Game.new(game_mode: game_modes(:match))
    game.save
    game.apply_game_mode
    assert_equal '東一局', game.latest_round.name
    assert game.players.all? { |player| player.score == 25_000 }
  end

  test '#apply_game_mode assign random score and final round when game mode is final_found' do
    game = Game.new(game_mode: game_modes(:final_round))
    game.save
    game.apply_game_mode
    assert_equal '南四局', game.latest_round.name
    assert game.players.all? { |player| player.score != 25_000 }
  end

  test '#deal_initial_hands creates 13 hands for each player' do
    @game.players.each do |player|
      assert_equal 0, player.hands.count
    end

    @game.deal_initial_hands
    @game.players.each do |player|
      assert_equal 13, player.hands.count
    end
  end

  test '#deal_initial_hands increases draw count(13 x 4 = 52)' do
    assert_equal 0, @game.draw_count

    @game.deal_initial_hands
    assert_equal 52, @game.draw_count
  end

  test '#deal_initial_hands creates new state' do
    @game.players.each do |player|
      assert_equal 1, player.player_states.count
    end

    @game.deal_initial_hands
    @game.players.each do |player|
      assert_equal 2, player.player_states.count
    end
  end

  test '#user_player' do
    assert @game.user_player.user_id.present?
    assert_not @game.user_player.ai_id.present?
  end

  test '#ais' do
    @game.ais.each do |ai|
      assert ai.ai_id.present?
      assert_not ai.user_id.present?
    end
  end

  test '#host' do
    assert_equal @game.host.seat_order, @game.latest_round.host_seat_number
  end

  test '#children' do
    @game.children.each do |child|
      assert child.id != @game.host.id
    end
  end

  test '#current_player returns player at current seat' do
    expected = @game.players.find_by!(seat_order: @game.current_seat_number)
    assert_equal expected, @game.current_player
  end

  test '#advance_current_player! changes current_player to next_player' do
    players = @game.players
    players.each_with_index do |player, seat_number|
      assert_equal player, @game.current_player

      @game.advance_current_player!
      next_seat_number = (seat_number + 1) % players.count
      assert_equal players[next_seat_number], @game.current_player
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
    current_player = @game.current_player
    manzu_1, manzu_2 = set_hands('m12', current_player)
    assert_equal [ manzu_1, manzu_2 ], current_player.hands
    assert_equal [], current_player.rivers

    @game.discard_for_current_player(manzu_1.id)
    assert_equal [ manzu_2.tile ], current_player.hands.map(&:tile)
    assert_equal [ manzu_1.tile ], current_player.rivers.map(&:tile)
  end

  test '#discard_for_current_player increments current_step_number and creates new step' do
    manzu_1 = set_hands('m1', @game.current_player).first
    before_step_number = @game.current_step_number
    @game.discard_for_current_player(manzu_1.id)
    assert_equal before_step_number + 1, @game.current_step_number
  end

  test '#latest_round returns round with maximum number' do
    max_number = @game.rounds.maximum(:number)
    expected = @game.rounds.find_by(number: max_number)
    assert_equal expected, @game.latest_round
  end

  test '#latest_honba returns honba with maximum number for latest_round' do
    max_number = @game.latest_round.honbas.maximum(:number)
    expected = @game.latest_round.honbas.find_by(number: max_number)
    assert_equal expected, @game.latest_honba
  end

  test '#current_round_name' do
    @game.latest_round.update!(number: 0)
    assert_equal '東一局', @game.current_round_name

    @game.latest_round.update!(number: 1)
    assert_equal '東二局', @game.current_round_name

    @game.latest_round.update!(number: 4)
    assert_equal '南一局', @game.current_round_name
  end

  test '#current_honba_name' do
    @game.latest_honba.update!(number: 0)
    assert_equal '〇本場', @game.current_honba_name

    @game.latest_honba.update!(number: 1)
    assert_equal '一本場', @game.current_honba_name

    @game.latest_honba.update!(number: 4)
    assert_equal '四本場', @game.current_honba_name
  end

  test '#current_step' do
    target_number = 2
    @game.update!(current_step_number: target_number)
    expected_step = @game.latest_honba.steps.find_by!(number: target_number)

    assert_equal expected_step, @game.current_step
  end

  test '#remaining_tile_count' do
    @game.latest_honba.update!(draw_count: 0)
    @game.latest_honba.update!(kan_count: 0)
    assert_equal 122, @game.remaining_tile_count

    @game.latest_honba.update!(draw_count: 10)
    assert_equal 112, @game.remaining_tile_count

    @game.latest_honba.update!(kan_count: 2)
    assert_equal 110, @game.remaining_tile_count
  end

  test '#dora_indicator_tiles' do
    @game.latest_honba.update!(kan_count: 0)
    assert_equal [ Tile, NilClass, NilClass, NilClass, NilClass ], @game.dora_indicator_tiles.map(&:class)

    @game.latest_honba.update!(kan_count: 1)
    assert_equal [ Tile, Tile, NilClass, NilClass, NilClass ], @game.dora_indicator_tiles.map(&:class)

    @game.latest_honba.update!(kan_count: 2)
    assert_equal [ Tile, Tile, Tile, NilClass, NilClass ], @game.dora_indicator_tiles.map(&:class)

    @game.latest_honba.update!(kan_count: 3)
    assert_equal [ Tile, Tile, Tile, Tile, NilClass ], @game.dora_indicator_tiles.map(&:class)

    @game.latest_honba.update!(kan_count: 4)
    assert_equal [ Tile, Tile, Tile, Tile, Tile ], @game.dora_indicator_tiles.map(&:class)
  end

  test '#riichi_stick_count' do
    @game.latest_honba.update!(riichi_stick_count: 0)
    assert_equal 0, @game.riichi_stick_count

    @game.latest_honba.update!(riichi_stick_count: 1)
    assert_equal 1, @game.riichi_stick_count
  end

  test '#apply_furo moves tile from hands to melds' do
    ai = @game.ais.sample
    set_player_turn(@game, ai)
    user = @game.user_player
    manzu_3 = set_rivers('m3', ai).first
    manzu_1, manzu_2, haku = set_hands('m12 z1', user)

    furo_ids = [ manzu_1.id, manzu_2.id ]
    @game.apply_furo(:chi, furo_ids, manzu_3.tile.id)
    expected = [ manzu_1.tile, manzu_2.tile, manzu_3.tile ]

    assert_equal [ haku.tile ], user.hands.map(&:tile)
    user.melds.each { |meld| assert expected.include?(meld.tile) }
  end

  test '#apply_furo increments current_step_number and creates new step' do
    ai = @game.ais.sample
    set_player_turn(@game, ai)
    before_step_number = @game.current_step_number
    manzu_1, manzu_2 = set_hands('m12', @game.user_player)
    furo_ids = [ manzu_1.id, manzu_2.id ]
    @game.apply_furo(:chi, furo_ids, tiles(:first_manzu_3).id)
    assert_equal before_step_number + 1, @game.current_step_number
  end

  test '#advance_next_round! creates new round' do
    before_round_count = @game.rounds.count
    before_round_number = @game.rounds.order(:number).last.number

    @game.advance_next_round!
    assert_equal before_round_count  + 1, @game.rounds.count
    assert_equal before_round_number + 1, @game.rounds.maximum(:number)
  end

  test '#advance_next_round! resets current_step_number to 0' do
    @game.update!(current_step_number: 100)
    @game.advance_next_round!
    assert_equal 0, @game.current_step_number
  end

  test '#advance_next_round! advances current_seat_number' do
    before_current_seat_number = @game.current_seat_number

    @game.advance_next_round!
    expected = (before_current_seat_number + 1) % @game.players.count
    assert_equal expected, @game.current_seat_number

    @game.advance_next_round!
    expected = (before_current_seat_number + 2) % @game.players.count
    assert_equal expected, @game.current_seat_number
  end

  test '#advance_next_round! creates every player new game_record' do
    @game.players.each do |player|
      assert_equal 1, player.game_records.count
    end

    @game.advance_next_round!
    @game.players.each do |player|
      assert_equal 2, player.game_records.count
    end

    @game.advance_next_round!
    @game.players.each do |player|
      assert_equal 3, player.game_records.count
    end
  end

  test '#advance_next_round! updates score by addition point' do
    player = @game.players.sample
    assert_equal 25000, player.score
    player.add_point(12000)

    @game.advance_next_round!
    assert_equal 37000, player.score
  end

  test '#advance_next_round! resets riichi_stick_count to 0 when ryukyoku is false' do
    @game.latest_honba.update!(riichi_stick_count: 1)
    @game.advance_next_round!(ryukyoku: false)
    assert_equal 0, @game.latest_honba.riichi_stick_count
  end

  test '#advance_next_round! carries over riichi_stick_count when ryukyoku is true' do
    @game.latest_honba.update!(riichi_stick_count: 1)
    @game.advance_next_round!(ryukyoku: true)
    assert_equal 1, @game.latest_honba.riichi_stick_count
  end

  test '#advance_next_honba! creates new honba' do
    before_honba_count = @game.latest_round.honbas.count
    before_honba_number = @game.latest_honba.number

    @game.advance_next_honba!
    assert_equal before_honba_count + 1, @game.latest_round.honbas.count
    assert_equal before_honba_number + 1, @game.latest_honba.number
  end

  test '#advance_next_honba! resets current_seat_number' do
    initial_current_seat_number = @game.current_seat_number
    next_current_seat_number = initial_current_seat_number + 1
    @game.update!(current_seat_number: next_current_seat_number)

    assert_not_equal initial_current_seat_number, @game.current_seat_number
    @game.advance_next_honba!
    assert_equal initial_current_seat_number, @game.current_seat_number
  end

  test '#advance_next_honba! resets current_step_number to 0' do
    @game.update!(current_step_number: 100)
    @game.advance_next_honba!
    assert_equal 0, @game.current_step_number
  end

  test '#advance_next_honba! creates every player new game_record' do
    @game.players.each do |player|
      assert_equal 1, player.game_records.count
    end

    @game.advance_next_honba!
    @game.players.each do |player|
      assert_equal 2, player.game_records.count
    end

    @game.advance_next_honba!
    @game.players.each do |player|
      assert_equal 3, player.game_records.count
    end
  end

  test '#advance_next_honba! updates score by addition point' do
    assert_equal 25000, @game.host.score
    @game.host.add_point(12000)

    @game.advance_next_honba!
    assert_equal 37000, @game.host.score
  end

  test '#advance_next_honba! resets riichi_stick_count to 0 when ryukyoku is false' do
    @game.latest_honba.update!(riichi_stick_count: 1)
    @game.advance_next_honba!(ryukyoku: false)
    assert_equal 0, @game.latest_honba.riichi_stick_count
  end

  test '#advance_next_honba! carries over riichi_stick_count when ryukyoku is true' do
    @game.latest_honba.update!(riichi_stick_count: 1)
    @game.advance_next_honba!(ryukyoku: true)
    assert_equal 1, @game.latest_honba.riichi_stick_count
  end

  test '#find_ron_players returns players that can_ron? == true' do
    player_1 = Minitest::Mock.new
    player_2 = Minitest::Mock.new
    player_3 = Minitest::Mock.new
    tile = tiles(:first_manzu_1)

    player_1.expect(:can_ron?, false, [ tile ])
    player_2.expect(:can_ron?, true,  [ tile ])
    player_3.expect(:can_ron?, true,  [ tile ])

    @game.stub(:other_players, [ player_1, player_2, player_3 ]) do
      result = @game.find_ron_players(tile)
      assert_equal [ player_2, player_3 ], result
    end
  end

  test '#find_ron_players returns empty array when nobody can ron' do
    player_1 = Minitest::Mock.new
    player_2 = Minitest::Mock.new
    player_3 = Minitest::Mock.new
    tile = tiles(:first_manzu_1)

    player_1.expect(:can_ron?, false, [ tile ])
    player_2.expect(:can_ron?, false, [ tile ])
    player_3.expect(:can_ron?, false, [ tile ])

    @game.stub(:other_players, [ player_1, player_2, player_3 ]) do
      result = @game.find_ron_players(tile)
      assert_empty result
    end
  end

  test '#build_ron_score_statements' do
    ron_player_1 = @game.ais[0]
    ron_player_2 = @game.ais[1]
    set_hands('m123456789 p22 s45', ron_player_1, drawn: false)
    set_hands('m111222333 p22 s33', ron_player_2, drawn: false)
    discarded_tile = tiles(:first_souzu_3)

    score_statements = @game.build_ron_score_statements(discarded_tile.id, [ ron_player_1.id, ron_player_2.id ])
    player_1_score_statements = score_statements[ron_player_1.id]
    player_2_score_statements = score_statements[ron_player_2.id]

    assert_equal 30, player_1_score_statements[:fu_total]
    assert_equal 3, player_1_score_statements[:han_total]
    assert_equal [
      { name: '平和', han: 1 },
      { name: '一気通貫', han: 2 }
    ], player_1_score_statements[:yaku_list]

    assert_equal 50, player_2_score_statements[:fu_total]
    assert_equal 4, player_2_score_statements[:han_total]
    assert_equal [
      { name: '対々和', han: 2 },
      { name: '三暗刻', han: 2 }
    ], player_2_score_statements[:yaku_list]
  end

  test '#give_ron_point adds point' do
    current_player = @game.current_player
    ron_player_1 = @game.ais[0]
    ron_player_2 = @game.ais[1]
    score_statement_table = {
      # 満貫（8000点）
      ron_player_1.id.to_s => {
        tsumo: false,
        han_total: 5,
        fu_total: 30
      },
      # 跳萬（12000点）
      ron_player_2.id.to_s => {
        tsumo: false,
        han_total: 7,
        fu_total: 30
      }
    }

    assert_equal 0, current_player.point
    assert_equal 0, ron_player_1.point
    assert_equal 0, ron_player_2.point

    @game.give_ron_point(score_statement_table)
    assert_equal -20000, current_player.point
    assert_equal 8000, ron_player_1.point
    assert_equal 12000, ron_player_2.point
  end

  test '#give_bonus_point adds riichi_stick_count_point and honba_point' do
    winner = @game.current_player
    loser_1 = @game.ais[0]
    loser_2 = @game.ais[1]
    loser_3 = @game.ais[2]
    @game.latest_honba.update!(riichi_stick_count: 1, number: 1) # リーチ棒；1000点、本場：300点（100x3）

    assert_equal 0, winner.point
    assert_equal 0, loser_1.point
    assert_equal 0, loser_2.point
    assert_equal 0, loser_3.point

    @game.give_bonus_point
    assert_equal 1300, winner.point
    assert_equal -100, loser_1.point
    assert_equal -100, loser_2.point
    assert_equal -100, loser_3.point
  end

  test '#give_bonus_point adds bonus to a shimocha claimer following relation priority(shimocha → toimen → kamicha)' do
    loser = @game.players.detect { |p| p.wind_name == '東' }
    shimocha = @game.players.detect { |p| p.wind_name == '南' }
    toimen = @game.players.detect { |p| p.wind_name == '西' }
    kamicha = @game.players.detect { |p| p.wind_name == '北' }
    ron_player_ids = [ shimocha.id, toimen.id, kamicha.id ]
    @game.latest_honba.update!(riichi_stick_count: 1, number: 1)

    assert_equal 0, loser.point
    assert_equal 0, shimocha.point
    assert_equal 0, toimen.point
    assert_equal 0, kamicha.point

    @game.give_bonus_point(ron_player_ids:)
    assert_equal -900, loser.point
    assert_equal 1300, shimocha.point
    assert_equal  300, toimen.point
    assert_equal  300, kamicha.point
  end

  test '#give_bonus_point adds bonus to a toimen claimer following relation priority(shimocha → toimen → kamicha)' do
    loser = @game.players.detect { |p| p.wind_name == '東' }
    toimen = @game.players.detect { |p| p.wind_name == '西' }
    kamicha = @game.players.detect { |p| p.wind_name == '北' }
    ron_player_ids = [ toimen.id, kamicha.id ]
    @game.latest_honba.update!(riichi_stick_count: 1, number: 2)

    assert_equal 0, loser.point
    assert_equal 0, toimen.point
    assert_equal 0, kamicha.point

    @game.give_bonus_point(ron_player_ids:)
    assert_equal -1200, loser.point
    assert_equal 1600, toimen.point
    assert_equal 600, kamicha.point
  end

  test '#give_tsumo_point adds point' do
    winner = @game.players.detect { |p| p.wind_name == '東' }
    loser_1 = @game.players.detect { |p| p.wind_name == '南' }
    loser_2 = @game.players.detect { |p| p.wind_name == '西' }
    loser_3 = @game.players.detect { |p| p.wind_name == '北' }
    set_hands('m234567 p234 s23455', winner) # 天和 48000点の加点

    assert_equal 0, winner.point
    assert_equal 0, loser_1.point
    assert_equal 0, loser_2.point
    assert_equal 0, loser_3.point

    @game.give_tsumo_point
    assert_equal 48000, winner.point
    assert_equal -16000, loser_1.point
    assert_equal -16000, loser_2.point
    assert_equal -16000, loser_3.point
  end

  test '#give_tenpai_point adds 3000 point when there is exactly one tenpai player' do
    tenpai_player = @game.user_player
    no_ten_player_1 = @game.ais[0]
    no_ten_player_2 = @game.ais[1]
    no_ten_player_3 = @game.ais[2]
    set_hands('m123456789 p123 s1', @game.user_player)

    @game.give_tenpai_point
    assert_equal 3000, tenpai_player.point
    assert_equal -1000, no_ten_player_1.point
    assert_equal -1000, no_ten_player_2.point
    assert_equal -1000, no_ten_player_3.point
  end

  test '#give_tenpai_point adds +-1500 point when there is exactly two tenpai player' do
    tenpai_player_1 = @game.user_player
    tenpai_player_2 = @game.ais[0]
    no_ten_player_1 = @game.ais[1]
    no_ten_player_2 = @game.ais[2]
    set_hands('m123456789 p123 s1', tenpai_player_1)
    set_hands('m123456789 p123 s1', tenpai_player_2)

    @game.give_tenpai_point
    assert_equal  1500, tenpai_player_1.point
    assert_equal  1500, tenpai_player_2.point
    assert_equal -1500, no_ten_player_1.point
    assert_equal -1500, no_ten_player_2.point
  end

  test '#give_tenpai_point adds +-1500 point when there is exactly three tenpai player' do
    tenpai_player_1 = @game.user_player
    tenpai_player_2 = @game.ais[0]
    tenpai_player_3 = @game.ais[1]
    no_ten_player = @game.ais[2]
    set_hands('m123456789 p123 s1', tenpai_player_1)
    set_hands('m123456789 p123 s1', tenpai_player_2)
    set_hands('m123456789 p123 s1', tenpai_player_3)

    @game.give_tenpai_point
    assert_equal  1000, tenpai_player_1.point
    assert_equal  1000, tenpai_player_2.point
    assert_equal  1000, tenpai_player_3.point
    assert_equal -3000, no_ten_player.point
  end

  test '#give_tenpai_point does not add point when all players are no-ten' do
    no_ten_player_1 = @game.user_player
    no_ten_player_2 = @game.ais[0]
    no_ten_player_3 = @game.ais[1]
    no_ten_player_4 = @game.ais[2]

    @game.give_tenpai_point
    assert_equal 0, no_ten_player_1.point
    assert_equal 0, no_ten_player_2.point
    assert_equal 0, no_ten_player_3.point
    assert_equal 0, no_ten_player_4.point
  end

  test '#give_tenpai_point does not add point when all players are tenpai' do
    tenpai_player_1 = @game.user_player
    tenpai_player_2 = @game.ais[0]
    tenpai_player_3 = @game.ais[1]
    tenpai_player_4 = @game.ais[2]
    set_hands('m123456789 p123 s1', tenpai_player_1)
    set_hands('m123456789 p123 s1', tenpai_player_2)
    set_hands('m123456789 p123 s1', tenpai_player_3)
    set_hands('m123456789 p123 s1', tenpai_player_4)

    @game.give_tenpai_point
    assert_equal 0, tenpai_player_1.point
    assert_equal 0, tenpai_player_2.point
    assert_equal 0, tenpai_player_3.point
    assert_equal 0, tenpai_player_4.point
  end

  test '#host_winner? return true when host get point' do
    assert_not @game.host_winner?
    @game.host.add_point(1000)
    assert @game.host_winner?
  end

  test '#undo_step decrements current_step_number' do
    @game.update!(current_step_number: 3)
    @game.undo_step
    assert_equal 2, @game.current_step_number
  end

  test '#redo_step increments current_step_number' do
    @game.update!(current_step_number: 1)
    @game.redo_step
    assert_equal 2, @game.current_step_number
  end

  test '#can_undo? returns true when current_step_number > 0' do
    @game.update!(current_step_number: 1)
    assert @game.can_undo?
  end

  test '#can_undo? returns false when current_step_number == 0' do
    @game.update!(current_step_number: 0)
    assert_not @game.can_undo?
  end

  test '#can_redo? returns true when there are steps ahead' do
    @game.update!(current_step_number: 0)
    @game.latest_honba.steps.create!(number: 1)
    assert @game.can_redo?
  end

  test '#can_redo? returns false when already at latest step' do
    latest_step_number = @game.latest_honba.steps.maximum(:number)
    @game.update!(current_step_number: latest_step_number)
    assert_not @game.can_redo?
  end

  test '#destroy_future_steps removes steps with higher numbers' do
    honba = @game.latest_honba
    future_step = honba.steps.create!(number: @game.current_step_number + 1)
    player = @game.players.first
    player.player_states.create!(step: future_step)

    assert_difference -> { honba.steps.count }, -1 do
      @game.destroy_future_steps
    end

    assert_nil honba.steps.find_by(id: future_step.id)
  end

  test '#destroy_future_steps leaves steps untouched when no higher numbers exist' do
    honba = @game.latest_honba
    before_count = honba.steps.count
    @game.destroy_future_steps
    assert_equal before_count, honba.steps.count
  end

  test '#sync_current_seat updates seat number to match current step player' do
    current_player = @game.current_player
    other_player = @game.players.where.not(id: current_player.id).first
    @game.update!(current_seat_number: other_player.seat_order)
    current_step = @game.current_step
    current_step.player_states.destroy_all
    current_step.player_states.create!(player: current_player)

    @game.sync_current_seat
    assert_equal current_player.seat_order, @game.current_seat_number
  end

  test '#sync_draw_count copies draw count from current_step' do
    @game.current_step.update!(draw_count: 7)
    @game.latest_honba.update!(draw_count: 0)

    @game.sync_draw_count

    assert_equal 7, @game.latest_honba.draw_count
  end

  test '#sync_kan_count copies kan count from current_step' do
    @game.current_step.update!(kan_count: 2)
    @game.latest_honba.update!(kan_count: 0)

    @game.sync_kan_count

    assert_equal 2, @game.latest_honba.kan_count
  end

  test '#sync_riichi_count copies riichi sticks from current_step' do
    @game.current_step.update!(riichi_stick_count: 3)
    @game.latest_honba.update!(riichi_stick_count: 0)

    @game.sync_riichi_count

    assert_equal 3, @game.latest_honba.riichi_stick_count
  end

  test '#game_end? returns true only when round count is exceeded' do
    @game.latest_round.update!(number: @game.game_mode.round_count - 2)
    assert_not @game.game_end?

    @game.latest_round.update!(number: @game.game_mode.round_count)
    assert @game.game_end?
  end

  test '#ranked_players returns players sorted by total score' do
    totals = [ 35_000, 28_000, 41_000, 22_000 ]
    @game.players.each_with_index do |player, index|
      player.game_records.last.update!(score: totals[index], point: 0)
    end

    expected_ids = @game.players
                        .map { |player| [ player.id, player.final_score ] }
                        .sort_by { |(_, total)| -total }
                        .map(&:first)

    assert_equal expected_ids, @game.ranked_players.map(&:id)
  end

  test '#rankings returns hash of player ids mapped to rank order' do
    totals = [ 30_000, 27_500, 39_000, 18_000 ]
    @game.players.each_with_index do |player, index|
      player.game_records.last.update!(score: totals[index], point: 0)
    end

    expected_pairs = @game.players
                          .map { |player| [ player.id, player.final_score ] }
                          .sort_by { |(_, total)| -total }
    expected_hash = expected_pairs.each_with_index.to_h { |(player_id, _), idx| [ player_id, idx + 1 ] }

    assert_equal expected_hash, @game.rankings
  end

  test '#reset_point sets all player points to zero' do
    @game.players.each_with_index do |player, index|
      player.latest_game_record.update!(point: 1000)
    end

    @game.reset_point
    assert @game.players.all? { |player| player.point.zero? }
  end

  test '#showing_uradora_necessary? returns true when any player riichi? with positive point' do
    players = @game.players.to_a
    @game.instance_variable_set(:@players, players)
    target = players.first

    target.stub(:riichi?, true) do
      target.stub(:point, 1500) do
        assert @game.showing_uradora_necessary?
      end
    end
  end

  test '#showing_uradora_necessary? returns false when no one riichi?' do
    @game.players.each { |player| player.current_state.update!(riichi: false) }
    assert_not @game.showing_uradora_necessary?
  end

  test '#showing_uradora_necessary? returns false when riichi? but point not positive' do
    player = @game.players.first
    player.current_state.update!(riichi: true)
    player.latest_game_record.update!(point: 0)

    assert_not @game.showing_uradora_necessary?
  end

  test '#showing_uradora_necessary? returns false when point is positive but no riichi' do
    player = @game.players.first
    player.current_state.update!(riichi: false)
    player.latest_game_record.update!(point: 1000)

    assert_not @game.showing_uradora_necessary?
  end

  test '#showing_uradora_necessary? returns true when point is positive and riichi' do
    player = @game.players.first
    player.current_state.update!(riichi: true)
    player.latest_game_record.update!(point: 1000)

    assert @game.showing_uradora_necessary?
  end
end

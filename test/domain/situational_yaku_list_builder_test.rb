# frozen_string_literal: true

require 'test_helper'

class SituationalYakuListBuilderTest < ActiveSupport::TestCase
  include GameTestHelper

  def setup
    @game = Game.create!(game_mode: game_modes(:tonnan))
    @game.setup_players(users(:ryo), ais('v0.1'))
    @game.deal_initial_hands
    @player = @game.user_player
  end

  test 'riichi? returns true after declaring riichi' do
    set_rivers('m1', @player)
    @player.current_state.update!(riichi: true)

    situational = SituationalYakuListBuilder.new(@player).build(nil)
    assert situational[:riichi]
  end

  test 'double_riichi? returns true on first turn riichi with no furo' do
    set_rivers('m1', @player) # 最初の捨て牌でリーチ宣言
    @player.current_state.update!(riichi: true)

    situational = SituationalYakuListBuilder.new(@player).build(nil)
    assert situational[:double_riichi]
  end

  test 'double_riichi? returns false when not first turn' do
    set_rivers('m12', @player) # 2巡目でリーチにするとダブル立直ではない
    @player.current_state.update!(riichi: true)

    situational = SituationalYakuListBuilder.new(@player).build(nil)
    assert_not situational[:double_riichi]
  end

  test 'double_riichi? returns false on first turn riichi with furo' do
    set_melds('m999=', @game.ais.sample) # 他のプレイヤーが副露済み
    set_rivers('m1', @player) # 最初の捨て牌でリーチ宣言
    @player.current_state.update!(riichi: true)

    situational = SituationalYakuListBuilder.new(@player).build(nil)
    assert_not situational[:double_riichi]
  end

  test 'ippatsu? returns true on first tsumo after riichi without any furo' do
    set_rivers('m1', @player)
    hands = set_hands('m123456789 s123 p9', @player)
    wining_tile = hands.last.tile
    @player.current_state.update!(riichi: true)

    next_step = @game.advance_step!
    @player.draw(wining_tile, next_step)

    situational = SituationalYakuListBuilder.new(@player).build(nil)
    assert situational[:ippatsu]
  end

  test 'ippatsu? returns false on first tsumo after riichi with furo' do
    set_rivers('m1', @player)
    hands = set_hands('m123456789 s123 p9', @player)
    wining_tile = hands.last.tile
    @player.current_state.update!(riichi: true)

    next_step = @game.advance_step!
    set_melds('m999=', @game.ais.sample)
    @player.draw(wining_tile, next_step)

    situational = SituationalYakuListBuilder.new(@player).build(nil)
    assert_not situational[:ippatsu]
  end

  test 'ippatsu? returns false on second tsumo after riichi without any furo' do
    set_rivers('m1', @player)
    hands = set_hands('m123456789 s123 p9', @player)
    losing_tile = hands.first.tile
    wining_tile = hands.last.tile
    @player.current_state.update!(riichi: true)

    next_step = @game.advance_step!
    @player.draw(losing_tile, next_step)
    @player.discard(@player.hands.detect(&:drawn).id, next_step)

    next_next_step = @game.advance_step!
    @player.draw(wining_tile, next_next_step)

    situational = SituationalYakuListBuilder.new(@player).build(nil)
    assert_not situational[:ippatsu]
  end

  test 'tenhou? returns true when no discards and no furo' do
    set_hands('m123456789 p99 s123', @player, drawn: true)

    situational = SituationalYakuListBuilder.new(@player).build(nil)
    assert situational[:tenhou]
  end

  test 'tenhou? returns false when someone discarded' do
    set_rivers('m1', @game.ais.sample)
    set_hands('m123456789 p99 s123', @player, drawn: true)

    situational = SituationalYakuListBuilder.new(@player).build(nil)
    assert_not situational[:tenhou]
  end

  test 'tenhou? returns false when any furo exists' do
    set_melds('m111=', @game.ais.sample)
    set_hands('m123456789 p99 s123', @player, drawn: true)

    situational = SituationalYakuListBuilder.new(@player).build(nil)
    assert_not situational[:tenhou]
  end

  test 'chiihou? returns true when player has no discards and no furo' do
    set_rivers('m1', @game.ais.sample) # 他のプライヤーのみ捨てている状態
    set_hands('m123456789 p99 s123', @player, drawn: true)

    situational = SituationalYakuListBuilder.new(@player).build(nil)
    assert situational[:chiihou]
  end

  test 'chiihou? returns false when player has discard' do
    set_rivers('m1', @player)
    set_hands('m123456789 p99 s123', @player, drawn: true)

    situational = SituationalYakuListBuilder.new(@player).build(nil)
    assert_not situational[:chiihou]
  end

  test 'chiihou? returns false when any furo exists' do
    set_melds('m111=', @game.ais.sample)
    set_hands('m123456789 p99 s123', @player, drawn: true)

    situational = SituationalYakuListBuilder.new(@player).build(nil)
    assert_not situational[:chiihou]
  end

  test 'haitei_tsumo? returns true at last draw' do
    @game.latest_honba.update!(draw_count: 122)
    set_hands('m123456789 p99 s123', @player, drawn: true)

    situational = SituationalYakuListBuilder.new(@player).build(nil)
    assert situational[:haitei]
  end

  test 'haitei_tsumo? returns false before last draw' do
    @game.latest_honba.update!(draw_count: 50)
    set_hands('m123456789 p99 s123', @player, drawn: true)

    situational = SituationalYakuListBuilder.new(@player).build(nil)
    assert_not situational[:haitei]
  end

  test 'houtei_ron? returns true at last draw' do
    @game.latest_honba.update!(draw_count: 122)
    wining_tile = set_hands('m123456789 p123 s9', @player).last.tile

    situational = SituationalYakuListBuilder.new(@player).build(wining_tile)
    assert situational[:houtei]
  end

  test 'houtei_ron? returns false before last draw' do
    @game.latest_honba.update!(draw_count: 50)
    wining_tile = set_hands('m123456789 p123 s9', @player).last.tile

    situational = SituationalYakuListBuilder.new(@player).build(wining_tile)
    assert_not situational[:houtei]
  end

  test 'rinshan_tsumo? returns true when drawn tile is rinshan' do
    set_hands('m123456789 p123 s99', @player, drawn: true, rinshan: true)

    situational = SituationalYakuListBuilder.new(@player).build(nil)
    assert situational[:rinshan]
  end

  test 'rinshan_tsumo? returns false when drawn tile is not rinshan' do
    set_hands('m123456789 p123 s99', @player, drawn: true)

    situational = SituationalYakuListBuilder.new(@player).build(nil)
    assert_not situational[:rinshan]
  end

  test 'chankan? returns true on kakan meld with winning hand' do
    meld = Meld.create!(tile: tiles(:fourth_souzu_1), kind: :kakan, player_state: @game.ais.sample.current_state, position: 4)
    set_hands('m123456789 p99 s23', @player)

    situational = SituationalYakuListBuilder.new(@player).build(meld)
    assert situational[:chankan]
  end

  test 'chankan? returns false when meld is not kakan' do
    meld = Meld.create!(tile: tiles(:fourth_souzu_1), kind: :daiminkan, player_state: @game.ais.sample.current_state, position: 0, from: :self)
    set_hands('m123456789 p99 s23', @player)

    situational = SituationalYakuListBuilder.new(@player).build(meld)
    assert_not situational[:chankan]
  end

  test 'chankan? returns false on not wining of kakan meld' do
    meld = Meld.create!(tile: tiles(:fourth_souzu_9), kind: :kakan, player_state: @game.ais.sample.current_state, position: 4)
    set_hands('m123456789 p99 s23', @player)

    situational = SituationalYakuListBuilder.new(@player).build(meld)
    assert_not situational[:chankan]
  end
end

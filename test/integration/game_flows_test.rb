# frozen_string_literal: true

require 'test_helper'

class GameFlowsTest < ActionDispatch::IntegrationTest
  include GameTestHelper

  def setup
    post '/guest_login'
    post games_path, params: { game_mode_id: game_modes(:tonpuu_mode).id }
    @game = find_game_from_url
    create_random_hands
    follow_redirect!
  end

  # テストの安定化のため、各プレイヤーの初期手配をロン、ツモ、ポン、チー、カンができない配牌に設定する
  def create_random_hands
    @game.players.each { |player| set_hands('m159 p159 s159 z1234', player) }
  end

  test 'first visit renders draw auto-submit form' do
    assert_dom "form[data-controller='auto-submit'][action='#{game_action_draw_path(@game)}']"
  end

  test 'draw action increases current player hand' do
    initial_hand_count = @game.current_player.hands.count
    post game_action_draw_path, params: { game_id: @game.id }
    assert_response :redirect
    @game.reload
    assert_equal initial_hand_count + 1, @game.current_player.hands.count
  end

  test 'discard action decrements current player hand' do
    set_user_turn(@game)
    initial_hand_count = @game.user_player.hands.count
    chosen_hand = @game.user_player.hands.sample
    post game_action_discard_path, params: { game_id: @game.id, chosen_hand_id: chosen_hand.id }
    assert_response :redirect
    @game.reload
    assert_equal initial_hand_count - 1, @game.user_player.hands.count
  end

  test 'AI player renders auto-submit forms in order: draw → choose → discard' do
    set_opponent_turn(@game)
    assert_dom "form[data-controller='auto-submit'][action='#{game_action_draw_path(@game)}']"
    post game_action_draw_path, params: { game_id: @game.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom "form[data-controller='auto-submit'][action='#{game_action_choose_path(@game)}']"
    get game_action_choose_path, params: { game_id: @game.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom "form[data-controller='auto-submit'][action='#{game_action_discard_path(@game)}']"
  end

  test 'user player renders forms in order: draw → discard' do
    set_user_turn(@game)
    assert_dom "form[data-controller='auto-submit'][action='#{game_action_draw_path(@game)}']"
    post game_action_draw_path, params: { game_id: @game.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom "form[action='#{game_action_discard_path(@game)}']"
    @game.reload
    chosen_hand = @game.current_player.hands.sample
    post game_action_discard_path, params: { game_id: @game.id, chosen_hand_id: chosen_hand.id }
    assert_response :redirect
  end

  test 'next player draws when current player discards and not steal' do
    before_player = @game.current_player.dup
    chosen_hand = @game.current_player.hands.sample
    post game_action_discard_path, params: { game_id: @game.id, chosen_hand_id: chosen_hand.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom "form[data-controller='auto-submit'][action='#{game_action_draw_path(@game)}']"
    assert_not_equal before_player, @game.current_player
  end

  test 'renders selectable hands only when drawn user turn' do
    set_user_turn(@game)
    assert_not_dom 'input[type=radio][name=?]', 'chosen_hand_id'
    post game_action_draw_path, params: { game_id: @game.id }
    assert_response :redirect
    follow_redirect!
    assert_dom 'input[type=radio][name=chosen_hand_id]'
  end

  test 'renders furos only when user can furo' do
    set_opponent_turn(@game)
    opponent = @game.current_player
    set_hands('m1', opponent)
    set_hands('m11 z1', @game.user_player)

    manzu_1 = opponent.hands.first
    post game_action_discard_path, params: { game_id: @game.id, chosen_hand_id: manzu_1.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][method=?]', game_action_furo_path(@game), 'post' do
      assert_dom 'input[type=hidden][name=?]', 'discarded_tile_id'
      assert_dom 'input[type=hidden][name=?]', 'furo_type'
      assert_dom 'input[type=hidden][name=?]', 'furo_ids[]', minimum: 1
    end

    assert_dom 'form[action=?][method=?]', game_action_through_path(@game), 'post' do
      assert_dom 'button[type=submit]', { text: 'スルー', count: 1 }
    end
  end

  test 'renders Ron form (with hidden) when user can ron' do
    set_opponent_turn(@game)
    set_hands('m123456789 p23 s99', @game.user_player)
    set_hands('p1', @game.current_player)

    pinzu_1 = @game.current_player.hands.first
    post game_action_discard_path, params: { game_id: @game.id, chosen_hand_id: pinzu_1.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][method=?]', game_action_ron_path(@game), 'post' do
      assert_dom 'button[type=submit]', { text: 'ロン', count: 1 }
      assert_dom 'input[type=hidden][name=?]', 'discarded_tile_id', count: 1
      assert_dom 'input[type=hidden][name=?]', 'ron_claimer_ids[]', minimum: 1
    end

    assert_dom 'form[action=?][method=?]', game_action_through_path(@game), 'post' do
      assert_dom 'button[type=submit]', { text: 'スルー', count: 1 }
    end
  end

  test 'renders Tsumo form when user can tsumo' do
    set_user_turn(@game)
    set_hands('m123456789 p23 s99', @game.user_player)
    assign_draw_tile('p1', @game)
    post game_action_draw_path, params: { game_id: @game.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][method=?]', game_action_tsumo_path(@game), 'post' do
      assert_dom 'button[type=submit]', { text: 'ツモ', count: 1 }
    end

    assert_dom 'form[action=?][method=?]', game_action_through_path(@game), 'post' do
      assert_dom 'button[type=submit]', { text: 'スルー', count: 1 }
    end
  end

  test 'advances to next honba when host player tsumo' do
    host = @game.user_player
    assign_host_player(host, @game)
    set_user_turn(@game)
    set_hands('m123456789 p23 s99', host)
    assign_draw_tile('p1', @game)

    before_honbas_count = @game.latest_round.honbas.count
    before_honba_number = @game.latest_honba.number
    before_step_number  = @game.current_step_number

    assert_dom 'span', text: '東一局'
    assert_dom 'span', text: '〇本場'
    post game_action_draw_path, params: { game_id: @game.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    post game_action_tsumo_path, params: { game_id: @game.id }
    assert_response :redirect
    follow_redirect!

    assert_dom "form[data-controller='auto-submit'][action='#{game_action_draw_path(@game)}']"
    assert_dom 'span', text: '東一局'
    assert_dom 'span', text: '一本場'

    @game.reload
    assert_equal before_honbas_count + 1, @game.latest_round.honbas.count
    assert_equal before_honba_number + 1, @game.latest_honba.number
    assert_equal 0, @game.current_step_number
  end

  test 'advances to next round when non-host player tsumo' do
    host = @game.opponents.sample
    assign_host_player(host, @game)
    set_user_turn(@game)
    set_hands('m123456789 p23 s99', @game.user_player)
    assign_draw_tile('p1', @game)

    before_rounds_count = @game.rounds.count
    before_round_number = @game.latest_round.number
    before_step_number  = @game.current_step_number

    assert_dom 'span', text: '東一局'
    assert_dom 'span', text: '〇本場'
    post game_action_draw_path, params: { game_id: @game.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    post game_action_tsumo_path, params: { game_id: @game.id }
    assert_response :redirect
    follow_redirect!

    assert_dom "form[data-controller='auto-submit'][action='#{game_action_draw_path(@game)}']"
    assert_dom 'span', text: '東二局'
    assert_dom 'span', text: '〇本場'

    @game.reload
    assert_equal before_rounds_count + 1, @game.rounds.count
    assert_equal before_round_number + 1, @game.latest_round.number
    assert_equal 0, @game.current_step_number
  end

  test 'advances to next honba when host player ron' do
    host = @game.user_player
    assign_host_player(host, @game)
    set_hands('m123456789 p23 s99', host)

    set_opponent_turn(@game)
    opponent = @game.current_player
    set_hands('p1', opponent)

    before_honbas_count = @game.latest_round.honbas.count
    before_honba_number = @game.latest_honba.number
    before_step_number  = @game.current_step_number

    assert_dom 'span', text: '東一局'
    assert_dom 'span', text: '〇本場'

    pinzu_1 = opponent.hands.first
    post game_action_discard_path, params: { game_id: @game.id, chosen_hand_id: pinzu_1.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    post game_action_ron_path, params: { game_id: @game.id, discarded_tile_id: pinzu_1.tile.id, ron_claimer_ids: [ host.id ] }
    assert_response :redirect
    follow_redirect!

    assert_dom "form[data-controller='auto-submit'][action='#{game_action_draw_path(@game)}']"
    assert_dom 'span', text: '東一局'
    assert_dom 'span', text: '一本場'

    @game.reload
    assert_equal before_honbas_count + 1, @game.latest_round.honbas.count
    assert_equal before_honba_number + 1, @game.latest_honba.number
    assert_equal 0, @game.current_step_number
  end

  test 'advances to next round when non-host player ron' do
    host = @game.opponents.sample
    assign_host_player(host, @game)
    set_opponent_turn(@game)
    set_hands('p1', host)
    set_hands('m123456789 p23 s99', @game.user_player)

    before_rounds_count = @game.rounds.count
    before_round_number = @game.latest_round.number
    before_step_number  = @game.current_step_number

    assert_dom 'span', text: '東一局'
    assert_dom 'span', text: '〇本場'

    pinzu_1 = host.hands.first
    post game_action_discard_path, params: { game_id: @game.id, chosen_hand_id: pinzu_1.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    post game_action_ron_path, params: { game_id: @game.id, discarded_tile_id: pinzu_1.tile.id, ron_claimer_ids: [ @game.user_player.id ] }
    assert_response :redirect
    follow_redirect!

    assert_dom "form[data-controller='auto-submit'][action='#{game_action_draw_path(@game)}']"
    assert_dom 'span', text: '東二局'
    assert_dom 'span', text: '〇本場'

    @game.reload
    assert_equal before_rounds_count + 1, @game.rounds.count
    assert_equal before_round_number + 1, @game.latest_round.number
    assert_equal 0, @game.current_step_number
  end
end

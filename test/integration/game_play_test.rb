# frozen_string_literal: true

require 'test_helper'

class GamePlayTest < ActionDispatch::IntegrationTest
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

  test 'next player draws when current player discards or not steal' do
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

  test 'renders Ron auto-form (with hidden) when ai can ron' do
    set_user_turn(@game)
    opponent = @game.opponents.sample
    set_hands('m123456789 p23 s99', opponent)
    set_hands('p1', @game.user_player)

    pinzu_1 = @game.user_player.hands.first
    post game_action_discard_path, params: { game_id: @game.id, chosen_hand_id: pinzu_1.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][method=?][data-controller=?]', game_action_ron_path(@game), 'post', 'auto-submit' do
      assert_dom 'input[type=hidden][name=?]', 'discarded_tile_id', count: 1
      assert_dom 'input[type=hidden][name=?]', 'ron_claimer_ids[]', minimum: 1
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

    assert_dom 'form[action=?][method=?]', game_action_pass_path(@game), 'get' do
      assert_dom 'button[type=submit]', { text: 'パス', count: 1 }
    end
  end

  test 'renders Tsumo auto-form when ai can tsumo' do
    set_opponent_turn(@game)
    set_hands('m123456789 p23 s99', @game.current_player)
    assign_draw_tile('p1', @game)
    post game_action_draw_path, params: { game_id: @game.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][method=?][data-controller=?]', game_action_tsumo_path(@game), 'post', 'auto-submit'
  end

  test 'renders selectable hands form when user select tsumo_pass' do
    set_user_turn(@game)
    set_hands('m123456789 p23 s99', @game.user_player)
    assign_draw_tile('p1', @game)
    post game_action_draw_path, params: { game_id: @game.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    get game_action_pass_path(@game)
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'input[type=radio][name=chosen_hand_id]'
  end


  test 'advances to next honba when host player tsumo' do
    host = @game.user_player
    assign_host(host, @game)
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
    assign_host(host, @game)
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
    assign_host(host, @game)
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
    assign_host(host, @game)
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

  test 'host mangan ron updates score: +12000 to winner, -12000 to loser, bonus 1600' do
    host = @game.user_player
    assign_host(host, @game)
    set_hands('m234567 p23 s23455', host, drawn: false) # 4筒ロンで親萬 12000点の加点
    set_opponent_turn(@game)
    opponent = @game.current_player
    set_hands('p4', opponent)
    @game.latest_honba.update!(riichi_stick_count: 1, number: 2) # リーチ棒：1000点、本場：300x2 = 600点

    assert_dom %(div[data-player-board-test-id="#{host.id}"]) do
      assert_dom %(div[data-role="score"]), text: '25000'
    end

    assert_dom %(div[data-player-board-test-id="#{opponent.id}"]) do
      assert_dom %(div[data-role="score"]), text: '25000'
    end

    pinzu_4 = opponent.hands.first
    post game_action_discard_path, params: { game_id: @game.id, chosen_hand_id: pinzu_4.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    post game_action_ron_path, params: { game_id: @game.id, discarded_tile_id: pinzu_4.tile.id, ron_claimer_ids: [ host.id ] }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom %(div[data-player-board-test-id="#{host.id}"]) do
      assert_dom %(div[data-role="score"]), text: '38600' # 25000 + 12000 + 1000 + 600
    end

    assert_dom %(div[data-player-board-test-id="#{opponent.id}"]) do
      assert_dom %(div[data-role="score"]), text: '12400' # 25000 - 12000 - 600
    end
  end

  test 'host mangan tsumo updates score: +12000 to host, -4000 to children' do
    host = @game.user_player
    assign_host(host, @game)
    set_hands('m234567 p23 s23455', host, drawn: false) # 4筒ツモで親萬 12000点の加点
    set_rivers('m1', host)
    set_user_turn(@game)
    assign_draw_tile('p4', @game)
    @game.latest_honba.update!(riichi_stick_count: 1, number: 2) # リーチ棒：1000点、本場：300x2 = 600点

    @game.players.each do |player|
      assert_dom %(div[data-player-board-test-id="#{player.id}"]) do
        assert_dom %(div[data-role="score"]), text: '25000'
      end
    end

    post game_action_draw_path, params: { game_id: @game.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    post game_action_tsumo_path, params: { game_id: @game.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    @game.players.each do |player|
      assert_dom %(div[data-player-board-test-id="#{player.id}"]) do
        if player.host?
          assert_dom %(div[data-role="score"]), text: '38600' # 25000 + 12000 + 1000 + 600
        else
          assert_dom %(div[data-role="score"]), text: '20800' # 25000 - 4000 - 200
        end
      end
    end
  end

  test 'rotates wind when advances next round' do
    ton_wind_player = @game.players.ordered[0]
    nan_wind_player = @game.players.ordered[1]
    sha_wind_player = @game.players.ordered[2]
    pei_wind_player = @game.players.ordered[3]

    assert_dom %(div[data-player-board-test-id="#{ton_wind_player.id}"]) do
      assert_dom %(div[data-role="wind"]), text: '東'
    end

    assert_dom %(div[data-player-board-test-id="#{nan_wind_player.id}"]) do
      assert_dom %(div[data-role="wind"]), text: '南'
    end

    assert_dom %(div[data-player-board-test-id="#{sha_wind_player.id}"]) do
      assert_dom %(div[data-role="wind"]), text: '西'
    end

    assert_dom %(div[data-player-board-test-id="#{pei_wind_player.id}"]) do
      assert_dom %(div[data-role="wind"]), text: '北'
    end

    next_round_number = @game.latest_round.number + 1
    @game.latest_round.update!(number: next_round_number)
    @game.reload
    post game_action_draw_path, params: { game_mode_id: @game.id }
    assert_response :redirect
    follow_redirect!

    assert_dom %(div[data-player-board-test-id="#{ton_wind_player.id}"]) do
      assert_dom %(div[data-role="wind"]), text: '北'
    end

    assert_dom %(div[data-player-board-test-id="#{nan_wind_player.id}"]) do
      assert_dom %(div[data-role="wind"]), text: '東'
    end

    assert_dom %(div[data-player-board-test-id="#{sha_wind_player.id}"]) do
      assert_dom %(div[data-role="wind"]), text: '南'
    end

    assert_dom %(div[data-player-board-test-id="#{pei_wind_player.id}"]) do
      assert_dom %(div[data-role="wind"]), text: '西'
    end
  end

  test 'renders Riichi form when user_player is menzen tenpai' do
    set_user_turn(@game)
    set_hands('m123456789 p2 s11 z1', @game.user_player)
    assign_draw_tile('p3', @game)

    post game_action_draw_path, params: { game_id: @game.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][method=?]', game_action_riichi_path(@game), 'post' do
      assert_dom 'button[type=submit]', { text: 'リーチ', count: 1 }
    end

    assert_dom 'form[action=?][method=?]', game_action_pass_path(@game), 'get' do
      assert_dom 'button[type=submit]', { text: 'パス', count: 1 }
    end
  end

  test 'auto-submit Riichi when ai is menzen tenpai' do
    set_opponent_turn(@game)
    ai = @game.current_player
    set_hands('m123456789 p2 s11 z1', ai)
    assign_draw_tile('p3', @game)

    post game_action_draw_path, params: { game_id: @game.id }
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][method=?][data-controller=?]',
              game_action_riichi_path(@game), 'post', 'auto-submit'
  end

  test 'user can select only riichi candidates when riichi' do
    set_user_turn(@game)
    set_hands('m123456789 p2 s11 z1', @game.user_player)
    assign_draw_tile('p3', @game)

    post game_action_draw_path(@game)
    assert_response :redirect
    follow_redirect!

    @game.reload
    assert_response :success
    post game_action_riichi_path(@game)
    assert_response :redirect
    follow_redirect!

    assert_response :success
    candidates = @game.user_player.find_riichi_candidates
    non_candidates = @game.user_player.hands - candidates

    assert_dom 'input[type=radio][name="chosen_hand_id"]', count: candidates.count

    candidates.each do |hand|
      assert_dom 'input[type=radio][name="chosen_hand_id"][value=?]', hand.id.to_s
    end

    non_candidates.each do |hand|
      assert_not_dom 'input[type=radio][name="chosen_hand_id"][value=?]', hand.id.to_s
    end
  end

  test 'auto-submit riichi candidates when ai is riichi' do
    set_opponent_turn(@game)
    ai = @game.current_player
    set_hands('m123456789 p2 s11 z1', ai)
    assign_draw_tile('p3', @game)

    post game_action_draw_path, params: { game_id: @game.id }
    assert_response :redirect
    follow_redirect!

    @game.reload
    assert_response :success
    post game_action_riichi_path(@game)
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][method=?][data-controller=?]',
              game_action_discard_path(@game), 'post', 'auto-submit'
  end

  test 'discard drawn tile when riichi' do
    @game.current_player.current_state.update!(riichi: true)

    post game_action_draw_path(@game)
    assert_response :redirect
    follow_redirect!

    @game.reload
    hand_id = @game.current_player.hands.find_by(drawn: true).id.to_s
    assert_response :success
    assert_dom 'form[action=?][method=?][data-controller=?]', game_action_discard_path(@game), 'post', 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', 'chosen_hand_id', hand_id
    end
  end
end

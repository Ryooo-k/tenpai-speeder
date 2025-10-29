# frozen_string_literal: true

require 'test_helper'

class GameFlowTest < ActionDispatch::IntegrationTest
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

  test 'redirects to home with alert on unknown event' do
    post game_play_command_path(@game, params: { event: 'unknown_event' })
    assert_redirected_to home_path
    follow_redirect!
    assert_response :success
    assert_includes @response.body, '不明なイベント名です：unknown_event'
  end

  test 'first visit renders draw event with auto-submit form' do
    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end
  end

  test 'draw event increases current player hand' do
    before_hand_count = @game.current_player.hands.count
    post game_play_command_path(@game, params: { event: 'draw' })
    assert_response :redirect
    @game.reload
    assert_equal before_hand_count + 1, @game.current_player.hands.count
  end

  test 'discard event decrements current player hand' do
    user = @game.user_player
    set_player_turn(@game, user)
    before_hand_count = user.hands.count
    chosen_hand_id = user.hands.sample.id

    post game_play_command_path(@game, params: { event: 'discard', chosen_hand_id: })
    assert_response :redirect
    @game.reload
    assert_equal before_hand_count - 1, user.hands.count
  end

  test 'AI player renders auto-submit forms in order: draw → choose → discard' do
    set_player_turn(@game, @game.ais.sample)

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end
    post game_play_command_path(@game, params: { event: 'draw' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :choose
    end
    post game_play_command_path(@game, params: { event: 'choose' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :discard
    end
  end

  test 'user player renders forms in order: draw → discard' do
    set_player_turn(@game, @game.user_player)

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end
    post game_play_command_path(@game, params: { event: 'draw' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?]', game_play_command_path(@game) do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :discard
    end

    @game.reload
    chosen_hand_id = @game.current_player.hands.sample.id
    post game_play_command_path(@game, params: { event: 'discard', chosen_hand_id: })
    assert_response :redirect
  end

  test 'next player draws when current player discards and nobody not steal' do
    chosen_hand_id = @game.current_player.hands.sample.id
    next_player = @game.players.find_by(seat_order: @game.current_player.seat_order + 1)

    post game_play_command_path(@game, params: { event: 'discard', chosen_hand_id: })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    @game.reload
    assert_equal next_player, @game.current_player
  end

  test 'renders selectable hands when user drawn' do
    set_player_turn(@game, @game.user_player)

    post game_play_command_path(@game, params: { event: 'draw' })
    assert_response :redirect
    follow_redirect!
    assert_dom 'input[type=radio][name=chosen_hand_id]'
  end

  test 'renders furo form (with hidden) when user can furo' do
    ai = @game.ais.sample
    set_player_turn(@game, ai)
    set_hands('m1', ai)
    set_hands('m11 z1', @game.user_player)
    manzu_1 = ai.hands.first

    post game_play_command_path(@game, params: { event: 'discard', chosen_hand_id: manzu_1.id })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :furo_combinations do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :furo
      assert_dom 'input[type=hidden][name=?]', 'discarded_tile_id'
      assert_dom 'input[type=hidden][name=?]', 'furo_type'
      assert_dom 'input[type=hidden][name=?]', 'furo_ids[]', minimum: 1
    end

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :through do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :through
      assert_dom 'button[type=submit]', { text: 'スルー', count: 1 }
    end
  end

  test 'renders ron form (with hidden) when user can ron' do
    ai = @game.ais.sample
    set_player_turn(@game, ai)
    set_hands('p1', ai)
    set_hands('m123456789 p23 s99', @game.user_player)
    pinzu_1 = @game.current_player.hands.first

    post game_play_command_path(@game, params: { event: 'discard', chosen_hand_id: pinzu_1.id })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :ron do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :ron
      assert_dom 'button[type=submit]', { text: 'ロン', count: 1 }
      assert_dom 'input[type=hidden][name=?]', 'discarded_tile_id', count: 1
      assert_dom 'input[type=hidden][name=?]', 'ron_player_ids[]', minimum: 1
    end

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :through do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :through
      assert_dom 'button[type=submit]', { text: 'スルー', count: 1 }
    end
  end

  test 'renders ron auto-form (with hidden) when ai can ron' do
    ai = @game.ais.sample
    user = @game.user_player
    set_player_turn(@game, user)
    set_hands('m123456789 p23 s99', ai)
    set_hands('p1', user)
    pinzu_1 = user.hands.first

    post game_play_command_path(@game, params: { event: 'discard', chosen_hand_id: pinzu_1.id })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :ron
      assert_dom 'input[type=hidden][name=?]', 'discarded_tile_id', count: 1
      assert_dom 'input[type=hidden][name=?]', 'ron_player_ids[]', minimum: 1
    end

    assert_not_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :ron
    assert_not_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :through
  end

  test 'renders tsumo form when user can tsumo' do
    user = @game.user_player
    set_player_turn(@game, user)
    set_hands('m123456789 p23 s99', user)
    set_draw_tile('p1', @game)

    post game_play_command_path(@game, params: { event: 'draw' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :tsumo do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :tsumo
      assert_dom 'button[type=submit]', { text: 'ツモ', count: 1 }
    end

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :pass do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :pass
      assert_dom 'button[type=submit]', { text: 'パス', count: 1 }
    end
  end

  test 'renders tsumo auto-form when ai can tsumo' do
    ai = @game.ais.sample
    set_player_turn(@game, ai)
    set_hands('m123456789 p23 s99', ai)
    set_draw_tile('p1', @game)

    post game_play_command_path(@game, params: { event: 'draw' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :tsumo
    end

    assert_not_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :tsumo
    assert_not_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :pass
  end

  test 'renders selectable hands form when user select tsumo_pass' do
    user = @game.user_player
    set_player_turn(@game, user)
    set_hands('m123456789 p123 s99', user)

    assert_response :success
    post game_play_command_path(@game, params: { event: 'pass' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'input[type=radio][name=chosen_hand_id]'
  end

  test 'renders result when someone wins' do
    set_hands('m123456789 p123 s99', @game.host)

    assert_response :success
    post game_play_command_path(@game, params: { event: 'tsumo' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'h2', text: '結果'
  end

  test 'renders next round form when someone wins' do
    set_hands('m123456789 p123 s99', @game.host)

    assert_response :success
    post game_play_command_path(@game, params: { event: 'tsumo' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?]', game_play_command_path(@game) do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :agari
    end
    assert_dom 'input[type=?][value=?]', 'submit', '次局へ'
  end

  test 'renders result when ryukyoku' do
    @game.latest_honba.update!(draw_count: 122)

    post game_play_command_path(@game, params: { event: 'draw' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'h2', text: '結果'
  end

  test 'renders ryukyoku form when ryukyoku' do
    @game.latest_honba.update!(draw_count: 122)

    post game_play_command_path(@game, params: { event: 'draw' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?]', game_play_command_path(@game) do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :ryukyoku
    end
    assert_dom 'input[type=?][value=?]', 'submit', '次局へ'
  end

  test 'advances to next honba when host player tsumo' do
    set_hands('m123456789 p123 s99', @game.host)

    before_honbas_count = @game.latest_round.honbas.count
    before_honba_number = @game.latest_honba.number
    before_step_number  = @game.current_step_number

    assert_dom 'span', text: '東一局'
    assert_dom 'span', text: '〇本場'

    assert_response :success
    post game_play_command_path(@game, params: { event: 'tsumo' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    post game_play_command_path(@game, params: { event: 'agari' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end
    assert_dom 'span', text: '東一局'
    assert_dom 'span', text: '一本場'

    assert_equal before_honbas_count + 1, @game.latest_round.honbas.count
    assert_equal before_honba_number + 1, @game.latest_honba.number
    assert_equal 0, @game.current_step_number
  end

  test 'advances to next round when non-host player tsumo' do
    non_host_player = @game.children.sample
    set_hands('m123456789 p123 s99', non_host_player)
    set_player_turn(@game, non_host_player)

    before_rounds_count = @game.rounds.count
    before_round_number = @game.latest_round.number
    before_step_number  = @game.current_step_number

    assert_dom 'span', text: '東一局'
    assert_dom 'span', text: '〇本場'

    assert_response :success
    post game_play_command_path(@game, params: { event: 'tsumo' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    post game_play_command_path(@game, params: { event: 'agari' })
    assert_response :redirect
    follow_redirect!

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end
    assert_dom 'span', text: '東二局'
    assert_dom 'span', text: '〇本場'

    assert_equal before_rounds_count + 1, @game.rounds.count
    assert_equal before_round_number + 1, @game.latest_round.number
    assert_equal 0, @game.current_step_number
  end

  test 'advances to next honba when host player ron' do
    set_hands('m123456789 p23 s99', @game.host)
    non_host_player = @game.children.sample
    set_player_turn(@game, non_host_player)
    pinzu_1_id = set_hands('p1', non_host_player).first.tile.id

    before_honbas_count = @game.latest_round.honbas.count
    before_honba_number = @game.latest_honba.number
    before_step_number  = @game.current_step_number

    assert_dom 'span', text: '東一局'
    assert_dom 'span', text: '〇本場'

    post game_play_command_path(@game, params: { event: 'ron', discarded_tile_id: pinzu_1_id, ron_player_ids: [ @game.host.id ] })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    post game_play_command_path(@game, params: { event: 'agari' })
    assert_response :redirect
    follow_redirect!

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end
    assert_dom 'span', text: '東一局'
    assert_dom 'span', text: '一本場'

    assert_equal before_honbas_count + 1, @game.latest_round.honbas.count
    assert_equal before_honba_number + 1, @game.latest_honba.number
    assert_equal 0, @game.current_step_number
  end

  test 'advances to next round when non-host player ron' do
    non_host_player = @game.children.sample
    set_hands('m123456789 p23 s99', non_host_player)
    pinzu_1_id = set_hands('p1', @game.host).first.tile.id

    before_rounds_count = @game.rounds.count
    before_round_number = @game.latest_round.number
    before_step_number  = @game.current_step_number

    assert_dom 'span', text: '東一局'
    assert_dom 'span', text: '〇本場'

    assert_response :success
    post game_play_command_path(@game, params: { event: 'ron', discarded_tile_id: pinzu_1_id, ron_player_ids: [ non_host_player.id ] })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    post game_play_command_path(@game, params: { event: 'agari' })
    assert_response :redirect
    follow_redirect!

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end
    assert_dom 'span', text: '東二局'
    assert_dom 'span', text: '〇本場'

    assert_equal before_rounds_count + 1, @game.rounds.count
    assert_equal before_round_number + 1, @game.latest_round.number
    assert_equal 0, @game.current_step_number
  end

  test 'advances to next round and next honba when ryukyoku' do
    before_rounds_count = @game.rounds.count
    before_round_number = @game.latest_round.number
    before_honba_number = @game.latest_honba.number
    before_step_number  = @game.current_step_number

    assert_dom 'span', text: '東一局'
    assert_dom 'span', text: '〇本場'

    assert_response :success
    post game_play_command_path(@game, params: { event: 'ryukyoku' })
    assert_response :redirect
    follow_redirect!

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end
    assert_dom 'span', text: '東二局'
    assert_dom 'span', text: '一本場'

    assert_equal before_rounds_count + 1, @game.rounds.count
    assert_equal before_round_number + 1, @game.latest_round.number
    assert_equal before_honba_number + 1, @game.latest_honba.number
    assert_equal 0, @game.current_step_number
  end

  test 'host mangan ron updates score: +12000 to winner, -12000 to loser and honba bonus' do
    @game.latest_honba.update!(riichi_stick_count: 1, number: 2) # リーチ棒：1000点、本場：300x2 = 600点

    host = @game.user_player
    loser = @game.ais.sample
    set_host(@game, host)
    set_hands('m234567 p23 s23455', host, drawn: false)    # 4筒ロンで親萬 12000点の加点
    set_player_turn(@game, loser)
    pinzu_4_id = set_hands('p4', loser).first.tile.id

    assert_dom %(div[data-player-board-test-id="#{host.id}"]) do
      assert_dom %(span[data-role="score"]), text: '25,000'
    end

    assert_dom %(div[data-player-board-test-id="#{loser.id}"]) do
      assert_dom %(span[data-role="score"]), text: '25,000'
    end

    assert_response :success
    post game_play_command_path(@game, params: { event: 'ron', discarded_tile_id: pinzu_4_id, ron_player_ids: [ @game.host.id ] })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    post game_play_command_path(@game, params: { event: 'agari' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom %(div[data-player-board-test-id="#{host.id}"]) do
      assert_dom %(span[data-role="score"]), text: '38,600' # 25000 + 12000 + 1000 + 600
    end

    assert_dom %(div[data-player-board-test-id="#{loser.id}"]) do
      assert_dom %(span[data-role="score"]), text: '12,400' # 25000 - 12000 - 600
    end
  end

  test 'host mangan tsumo updates score: +12000 to host, -4000 to children and honba bonus' do
    @game.latest_honba.update!(riichi_stick_count: 1, number: 2) # リーチ棒：1000点、本場：300x2 = 600点

    set_hands('m234567 p234 s23455', @game.host) # 親萬 12000点の加点
    set_rivers('m1', @game.host) # 天和対策

    @game.players.each do |player|
      assert_dom %(div[data-player-board-test-id="#{player.id}"]) do
        assert_dom %(span[data-role="score"]), text: '25,000'
      end
    end

    assert_response :success
    post game_play_command_path(@game, params: { event: 'tsumo' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    post game_play_command_path(@game, params: { event: 'agari' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    @game.players.each do |player|
      assert_dom %(div[data-player-board-test-id="#{player.id}"]) do
        if player.host?
          assert_dom %(span[data-role="score"]), text: '38,600' # 25000 + 12000 + 1000 + 600
        else
          assert_dom %(span[data-role="score"]), text: '20,800' # 25000 - 4000 - 200
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
      assert_dom %(span[data-role="wind"]), text: '東'
    end

    assert_dom %(div[data-player-board-test-id="#{nan_wind_player.id}"]) do
      assert_dom %(span[data-role="wind"]), text: '南'
    end

    assert_dom %(div[data-player-board-test-id="#{sha_wind_player.id}"]) do
      assert_dom %(span[data-role="wind"]), text: '西'
    end

    assert_dom %(div[data-player-board-test-id="#{pei_wind_player.id}"]) do
      assert_dom %(span[data-role="wind"]), text: '北'
    end

    post game_play_command_path(@game, params: { event: 'ryukyoku' })
    assert_response :redirect
    follow_redirect!

    assert_dom %(div[data-player-board-test-id="#{ton_wind_player.id}"]) do
      assert_dom %(span[data-role="wind"]), text: '北'
    end

    assert_dom %(div[data-player-board-test-id="#{nan_wind_player.id}"]) do
      assert_dom %(span[data-role="wind"]), text: '東'
    end

    assert_dom %(div[data-player-board-test-id="#{sha_wind_player.id}"]) do
      assert_dom %(span[data-role="wind"]), text: '南'
    end

    assert_dom %(div[data-player-board-test-id="#{pei_wind_player.id}"]) do
      assert_dom %(span[data-role="wind"]), text: '西'
    end
  end

  test 'renders riichi form when user is menzen tenpai' do
    user = @game.user_player
    set_player_turn(@game, user)
    set_hands('m123456789 p2 s11 z1', user)
    set_draw_tile('p3', @game)

    post game_play_command_path(@game, params: { event: 'draw' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :riichi do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :riichi
      assert_dom 'button[type=submit]', { text: 'リーチ', count: 1 }
    end

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :pass do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :pass
      assert_dom 'button[type=submit]', { text: 'パス', count: 1 }
    end
  end

  test 'auto-submit riichi when ai is menzen tenpai' do
    ai = @game.ais.sample
    set_player_turn(@game, ai)
    set_hands('m123456789 p2 s11 z1', ai)
    set_draw_tile('p3', @game)

    post game_play_command_path(@game, params: { event: 'draw' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :riichi
    end

    assert_not_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :riichi
    assert_not_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :pass
  end

  test 'user can select only riichi candidates when riichi' do
    user = @game.user_player
    set_player_turn(@game, user)
    set_hands('m123456789 p23 s11 z1', user)

    assert_response :success
    post game_play_command_path(@game, params: { event: 'riichi' })
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

  test 'auto-submit riichi choose when ai is riichi' do
    ai = @game.ais.sample
    set_player_turn(@game, ai)
    set_hands('m123456789 p23 s11 z1', ai)

    assert_response :success
    post game_play_command_path(@game, params: { event: 'riichi' })
    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :discard
      assert_dom 'input[type=hidden][name=?]', 'chosen_hand_id'
    end
  end

  test 'discard drawn tile when player is riichi' do
    @game.current_player.current_state.update!(riichi: true)

    post game_play_command_path(@game, params: { event: 'draw' })
    assert_response :redirect
    follow_redirect!

    @game.reload
    drawn_hand_id = @game.current_player.hands.find_by(drawn: true).id.to_s
    assert_response :success
    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', 'chosen_hand_id', drawn_hand_id
    end
  end
end

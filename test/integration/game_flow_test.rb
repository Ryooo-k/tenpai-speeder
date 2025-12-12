# frozen_string_literal: true

require 'test_helper'

class GameFlowTest < ActionDispatch::IntegrationTest
  include GameTestHelper
  include ActionView::Helpers::NumberHelper

  def setup
    post '/guest_login'
    post games_path, params: { game_mode_id: game_modes(:tonnan).id }
    @game = find_game_from_url
    set_random_hands
    follow_redirect!
  end

  # テストの安定化のため、各プレイヤーの初期手配をロン、ツモ、ポン、チー、カンができない配牌に設定する
  def set_random_hands
    @game.players.each { |player| set_hands('m159 p159 s159 z1234', player) }
  end

  def start_game(mode_fixture)
    post games_path, params: { game_mode_id: game_modes(mode_fixture).id }
    assert_response :redirect
    game = find_game_from_url
    follow_redirect!
    game
  end

  test 'create redirects home with alert when SaveError is raised on game start' do
    failing_flow = GameFlow.new(@game)

    failing_flow.stub(:run, ->(*) { raise GameFlow::SaveError }) do
      GameFlow.stub(:new, failing_flow) do
        post games_path, params: { game_mode_id: game_modes(:tonnan).id }
        assert_redirected_to home_path
        follow_redirect!

        assert_includes @response.body, 'ゲームの保存に失敗しました。時間をおいて再度お試しください。'
      end
    end
  end

  test 'rolls back and raises SaveError when db update fails' do
    current_player = @game.current_player
    chosen_hand_id = current_player.hands.sample.id
    before_hand = current_player.hands
    before_river = set_rivers('m123', current_player)

    step = @game.current_step
    failing_step = step.tap do |s|
      def s.update!(*)
        raise ActiveRecord::StatementInvalid
      end
    end

    error = assert_raises(GameFlow::SaveError) do
      @game.stub(:current_step, failing_step) do
        GameFlow.new(@game).run({ event: :discard, chosen_hand_id: })
      end
    end

    assert_equal 'ゲーム状態の保存に失敗しました。', error.message
    assert_kind_of ActiveRecord::ActiveRecordError, error.cause

    @game.reload
    assert_equal before_hand, @game.current_player.hands
    assert_equal before_river, @game.current_player.rivers
  end

  test 'play command redirects with alert when SaveError is raised' do
    failing_flow = GameFlow.new(@game)

    failing_flow.stub(:run, ->(*) { raise GameFlow::SaveError }) do
      GameFlow.stub(:new, failing_flow) do
        post game_play_command_path(@game), params: { event: 'draw' }
        assert_redirected_to game_play_path(@game)
        follow_redirect!

        assert_includes @response.body, 'ゲームの保存に失敗しました。時間をおいて再度お試しください。'
      end
    end
  end

  test '東南戦モードは、東一局・25000点・南四局で終了' do
    game = start_game(:tonnan)
    assert_equal '東一局', @game.latest_round.name
    assert_equal [ 25_000 ] * 4, @game.players.map { |player| player.game_records.last.score }
    assert_not @game.game_end?

    @game.latest_round.update!(number: @game.game_mode.round_count)
    assert_equal '南四局', @game.latest_round.name
    assert @game.game_end?

    payloads = nil
    @game.stub(:host_winner?, false) do
      payloads = GameFlow.new(@game).run({ event: :result, ryukyoku: false })
    end

    assert_equal 'game_end', payloads[:next_event]
  end

  test '東風戦モードは、東一局・25000点・東四局で終了' do
    game = start_game(:tonpuu)
    assert_equal '東一局', game.latest_round.name
    assert_equal [ 25_000 ] * 4, game.players.map { |player| player.game_records.last.score }
    assert_not game.game_end?

    game.latest_round.update!(number: game.game_mode.round_count)
    assert_equal '東四局', game.latest_round.name
    assert game.game_end?

    payloads = nil
    game.stub(:host_winner?, false) do
      payloads = GameFlow.new(game).run({ event: :result, ryukyoku: false })
    end

    assert_equal 'game_end', payloads[:next_event]
  end

  test '1局戦モードは、東一局・25000点・東一局で終了' do
    game = start_game(:single_game)
    assert_equal '東一局', game.latest_round.name
    assert_equal [ 25_000 ] * 4, game.players.map { |player| player.game_records.last.score }
    assert game.game_end?

    payloads = nil
    game.stub(:host_winner?, false) do
      payloads = GameFlow.new(game).run({ event: :result, ryukyoku: false })
    end

    assert_equal 'game_end', payloads[:next_event]
  end

  test '着順UP練習モードは、オーラス開始・合計10万点・南4局で終了' do
    game = start_game(:all_last)
    assert_equal '南四局', game.latest_round.name
    assert_not_equal [ 25_000 ] * 4, game.players.map { |player| player.game_records.last.score }
    assert_equal 100_000, game.players.sum { |player| player.game_records.last.score }
    assert game.game_end?

    payloads = nil
    game.stub(:host_winner?, false) do
      payloads = GameFlow.new(game).run({ event: :result, ryukyoku: false })
    end

    assert_equal 'game_end', payloads[:next_event]
  end

  test 'redirects to home with alert on unknown event' do
    logs = []
    unknown_event = 'unknown_event'

    Rails.logger.stub(:warn, ->(msg) { logs << msg }) do
      post game_play_command_path(@game), params: { event: unknown_event }
      assert_redirected_to game_play_path(@game)
      follow_redirect!
      assert_response :success
    end

    assert_includes @response.body, "不明なイベントです：#{unknown_event}"
    assert "[GameFlow] UnknownEvent: 不明なイベントです：#{unknown_event} (game_id=#{@game.id}, event=#{unknown_event})", logs.first
  end

  test 'first visit renders draw event with auto-submit form' do
    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end
  end

  test 'ai player event flow : draw_event(auto) → choose_event(auto) → discard_event(auto)' do
    set_player_turn(@game, @game.ais.sample)
    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end

    post game_play_command_path(@game), params: { event: 'draw' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :choose
    end

    chosen_hand_id = @game.current_player.hands.sample.id
    post game_play_command_path(@game), params: { event: 'choose', chosen_hand_id: }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :discard
    end
  end

  test 'user player event flow : draw_event(auto) → choose_event(manual) + discard_event' do
    set_player_turn(@game, @game.user_player)
    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end

    post game_play_command_path(@game), params: { event: 'draw' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_not_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit'
    assert_dom 'form[action=?]', game_play_command_path(@game) do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :discard
      assert_dom 'input[type=radio][name=chosen_hand_id]'
    end
  end

  test 'discard sets next_event to switch_event' do
    chosen_hand_id = @game.current_player.hands.sample.id
    post game_play_command_path(@game), params: { event: 'discard', chosen_hand_id: }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :switch_event
    end
  end

  test 'discard triggers advances to draw when nobody not furo, nobody not ron and not game_set' do
    set_player_turn(@game, @game.ais.first)
    chosen_hand = @game.current_player.hands.sample
    next_player = @game.players.find_by(seat_order: @game.current_player.seat_order + 1)

    post game_play_command_path(@game, params: { event: 'discard', chosen_hand_id: chosen_hand.id })
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    ron_eligible_players = @game.find_ron_players(chosen_hand.tile)
    is_furo = @game.user_player.can_furo?(chosen_hand.tile, @game.current_player)
    assert_not ron_eligible_players.present?
    assert_not is_furo
    assert_not @game.live_wall_empty?

    @game.reload
    assert_equal next_player, @game.current_player
    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end
  end

  test 'discard triggers confirm_ron when player can ron' do
    ai = @game.ais.sample
    set_player_turn(@game, ai)

    # ユーザーをテンパイにし、ロン可能な形にセット（1索でロン可能）
    set_hands('m123456789 p123 s1', @game.user_player)
    set_hands('s111', ai)
    winning_tile = ai.hands.first

    post game_play_command_path(@game), params: { event: 'discard', chosen_hand_id: winning_tile.id }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), 'ron' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_ron
      assert_dom 'input[type=hidden][name=?][value=?]', 'discarded_tile_id', winning_tile.tile.id
      assert_dom 'input[type=hidden][name=?]', 'ron_player_ids[]', minimum: 1
    end
  end

  test 'discard triggers ryukyoku when live_wall empty' do
    @game.latest_honba.update!(draw_count: 122)
    chosen_hand_id = @game.current_player.hands.sample.id

    post game_play_command_path(@game), params: { event: 'discard', chosen_hand_id: }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :ryukyoku
    end
  end

  test 'discard triggers confirm_furo when user can furo' do
    ai = @game.ais.sample
    set_player_turn(@game, ai)

    # 1萬をポンできる状態にセット
    set_hands('m11 p123456789 p12', @game.user_player)
    set_hands('m111', ai)
    chosen_hand_id = ai.hands.first.id

    post game_play_command_path(@game), params: { event: 'discard', chosen_hand_id: }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), 'furo_combinations' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_furo
      assert_dom 'input[type=hidden][name=?]', 'discarded_tile_id'
      assert_dom 'input[type=hidden][name=?][value=?]', 'furo', :true
      assert_dom 'input[type=hidden][name=?]', 'furo_type'
      assert_dom 'input[type=hidden][name=?]', 'furo_ids[]', minimum: 1
    end

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), 'through' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_furo
      assert_dom 'input[type=hidden][name=?][value=?]', 'furo', :false
    end
  end

  test 'kan adds new dora on confirm_furo with daiminkan' do
    ai = @game.ais.first
    user = @game.user_player
    set_player_turn(@game, ai)

    # ユーザーに1萬を3枚持たせ、AIに1萬を含む手牌をセットしてカン可能な状況にする
    set_hands('m111234567 p1234', user)
    set_hands('m1 p234567 s23456 z1', ai)

    kan_count_before = @game.latest_honba.kan_count
    discarded_hand = ai.hands.detect { |hand| hand.name == '1萬' }

    furo_ids = user.hands.select { |hand| hand.name == '1萬' }.map(&:id)
    post game_play_command_path(@game), params: {
      event: 'confirm_furo',
      furo: true,
      furo_type: :daiminkan,
      discarded_tile_id: discarded_hand.tile.id,
      furo_ids:
    }
    follow_redirect!

    assert_equal kan_count_before + 1, @game.reload.latest_honba.kan_count
  end

  test 'confirm_ron triggers result when ron player exist' do
    ai = @game.ais.first
    set_player_turn(@game, ai)

    # 1萬でロン和了の状態にセット
    set_hands('m1 p123456789 p123', @game.user_player)
    set_hands('m111', ai)
    discarded_tile_id = ai.hands.first.tile.id
    ron_player_id = @game.user_player.id

    post game_play_command_path(@game), params: { event: 'confirm_ron', discarded_tile_id:, ron_player_ids: [ ron_player_id ] }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), 'result' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :result
      assert_dom 'input[type=hidden][name=?][value=?]', :ryukyoku, :false
    end
  end

  test 'user passes but ai ron moves to result' do
    ai_discarder = @game.ais.first
    ai_ronner = @game.ais.second
    set_player_turn(@game, ai_discarder)

    # 1萬でロン和了できる状態にユーザーと別のAIをセット
    set_hands('m1 p123456789 p123', @game.user_player)
    set_hands('m1 p123456789 p123', ai_ronner)
    set_hands('m111', ai_discarder)
    discarded_tile = ai_discarder.hands.first

    post game_play_command_path(@game), params: { event: 'discard', chosen_hand_id: discarded_tile.id }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # スルー＝ユーザーを除外し、AIだけロンさせる
    post game_play_command_path(@game), params: { event: 'confirm_ron', discarded_tile_id: discarded_tile.tile.id, ron_player_ids: [ ai_ronner.id ] }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), 'result' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :result
      assert_dom 'input[type=hidden][name=?][value=?]', :ryukyoku, :false
    end
  end

  test 'through button sends empty ron_player_ids without error and advances play' do
    ai = @game.ais.first
    set_player_turn(@game, ai)

    # 1萬でロン和了の状態にセット（ユーザーのみロン可能）
    set_hands('m1 p123456789 p123', @game.user_player)
    set_hands('m111', ai)
    discarded_tile = ai.hands.first.tile
    next_player = @game.players.find_by(seat_order: ai.seat_order + 1)

    post game_play_command_path(@game), params: { event: 'discard', chosen_hand_id: ai.hands.first.id }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # スルー押下時は自身を除外し、空配列（空文字入り）で送る想定
    post game_play_command_path(@game), params: { event: 'confirm_ron', discarded_tile_id: discarded_tile.id, ron_player_ids: [ '' ] }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    @game.reload
    assert_equal next_player, @game.current_player
    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end
  end

  test 'confirm_furo triggers choose when user played pon' do
    ai = @game.ais.first
    set_player_turn(@game, ai)

    # 1萬でポンの状態にセット
    set_hands('m11 p123', @game.user_player)
    set_hands('m1 z123', ai)
    discarded_tile_id = ai.hands.first.tile.id
    furo_ids = [ @game.user_player.hands.first.id, @game.user_player.hands.second.id ]

    post game_play_command_path(@game), params: { event: 'confirm_furo', furo: true, furo_type: :pon, furo_ids:, discarded_tile_id: }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?]', game_play_command_path(@game) do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :discard
    assert_dom 'input[type=radio][name=chosen_hand_id]'
    end
  end

  test 'confirm_furo triggers choose when user played chi' do
    ai = @game.ais.first
    set_player_turn(@game, ai)

    # 1-2萬を持ち、3萬でチーできる状態にセット
    set_hands('m12 p3456789 z123', @game.user_player)
    set_hands('m3 z123', ai)
    discarded_tile = ai.hands.first.tile
    chi_ids = @game.user_player.hands.select { |h| h.suit == 'manzu' && h.number.in?([ 1, 2 ]) }.map(&:id)

    post game_play_command_path(@game), params: { event: 'confirm_furo', furo: true, furo_type: :chi, furo_ids: chi_ids, discarded_tile_id: discarded_tile.id }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?]', game_play_command_path(@game) do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :discard
      assert_dom 'input[type=radio][name=chosen_hand_id]'
    end
  end

  test 'confirm_furo triggers rinshan_draw when user played daiminkan' do
    ai = @game.ais.first
    set_player_turn(@game, ai)

    # 1萬を暗槓できる状態にセット（3枚所持＋捨て牌1枚）
    set_hands('m111 p3456789 z123', @game.user_player)
    set_hands('m1 z123', ai)
    discarded_tile = ai.hands.first.tile
    kan_ids = @game.user_player.hands.select { |h| h.suit == 'manzu' && h.number == 1 }.map(&:id)

    post game_play_command_path(@game), params: { event: 'confirm_furo', furo: true, furo_type: :daiminkan, furo_ids: kan_ids, discarded_tile_id: discarded_tile.id }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :rinshan_draw
    end
  end

  test 'confirm_furo advances to draw when no furo players' do
    ai = @game.ais.first
    set_player_turn(@game, ai)
    next_player = @game.players.find_by(seat_order: @game.current_player.seat_order + 1)

    post game_play_command_path(@game), params: { event: 'confirm_furo', furo: false }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    @game.reload
    assert_equal next_player, @game.current_player
    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end
  end

  test 'ryukyoku sets next_event to result' do
    post game_play_command_path(@game), params: { event: 'ryukyoku' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), 'result' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :result
      assert_dom 'input[type=hidden][name=?]', :ryukyoku
    end
  end

  test 'play screen shows undo, playback, and redo disabled buttons' do
    assert_dom 'form[action=?][data-testid=?]', game_play_undo_path(@game), 'undo' do
      assert_dom 'button[type=submit][disabled]', { text: '戻る', count: 1 }
    end

    assert_dom 'form[action=?][data-testid=?]', game_play_playback_path(@game), 'playback' do
      assert_dom 'button[type=submit][disabled]', { text: '▶︎', count: 1 }
    end

    assert_dom 'form[action=?][data-testid=?]', game_play_redo_path(@game), 'redo' do
      assert_dom 'button[type=submit][disabled]', { text: '進む', count: 1 }
    end
  end

  test 'undo button becomes enabled after game progresses' do
    post game_play_command_path(@game), params: { event: 'draw' }
    assert_response :redirect

    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-testid=?]', game_play_undo_path(@game), 'undo' do
      assert_dom 'button[type=submit]:not([disabled])', { text: '戻る', count: 1 }
    end

    assert_dom 'form[action=?][data-testid=?]', game_play_playback_path(@game), 'playback' do
      assert_dom 'button[type=submit][disabled]', { text: '▶︎', count: 1 }
    end

    assert_dom 'form[action=?][data-testid=?]', game_play_redo_path(@game), 'redo' do
      assert_dom 'button[type=submit][disabled]', { text: '進む', count: 1 }
    end
  end

  test 'redo and playback become enabled after pressing undo' do
    post game_play_command_path(@game), params: { event: 'draw' }
    assert_response :redirect

    follow_redirect!
    assert_response :success

    post game_play_undo_path(@game)
    assert_response :redirect

    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-testid=?]', game_play_playback_path(@game), 'playback' do
      assert_dom 'button[type=submit]:not([disabled])', { text: '▶︎', count: 1 }
    end

    assert_dom 'form[action=?][data-testid=?]', game_play_redo_path(@game), 'redo' do
      assert_dom 'button[type=submit]:not([disabled])', { text: '進む', count: 1 }
    end
  end

  test 'draw event increases current player hand' do
    before_hand_count = @game.current_player.hands.count

    post game_play_command_path(@game), params: { event: 'draw' }
    assert_response :redirect

    follow_redirect!
    assert_response :success

    @game.reload
    assert_equal before_hand_count + 1, @game.current_player.hands.count
  end

  test 'discard event decrements current player hand' do
    current_player = @game.current_player
    set_player_turn(@game, current_player)
    before_hand_count = current_player.hands.count
    chosen_hand_id = current_player.hands.sample.id

    post game_play_command_path(@game), params: { event: 'discard', chosen_hand_id: }
    assert_response :redirect

    @game.reload
    assert_equal before_hand_count - 1, current_player.hands.count
  end

  test 'discard event stores switch_event on latest step' do
    user = @game.user_player
    set_player_turn(@game, user)
    chosen_hand_id = user.hands.sample.id

    post game_play_command_path(@game, params: { event: 'discard', chosen_hand_id: })
    assert_response :redirect
    @game.reload

    latest_step = @game.latest_honba.steps.order(number: :desc).first
    assert_equal 'switch_event', latest_step.next_event
  end

  test 'playback removes future steps before replaying event' do
    honba = @game.latest_honba
    honba.steps.create!(number: 1)
    honba.steps.create!(number: 2)
    @game.update!(current_step_number: 0)

    post game_play_playback_path(@game), params: { event: 'draw' }
    assert_redirected_to game_play_path(@game)
    @game.reload

    assert_equal 0, @game.latest_honba.steps.maximum(:number)
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

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :furo_combinations do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_furo
      assert_dom 'input[type=hidden][name=?][value=?]', 'discarded_tile_id', manzu_1.tile.id
      assert_dom 'input[type=hidden][name=?]', 'furo_type'
      assert_dom 'input[type=hidden][name=?]', 'furo_ids[]', minimum: 1
    end

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :through do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_furo
      assert_dom 'button[type=submit]', { text: 'スルー', count: 1 }
    end
  end

  test 'renders ron form (with hidden) when user can ron' do
    ai = @game.ais.sample
    set_player_turn(@game, ai)
    set_hands('p1', ai)

    # 1筒でロン和了できる状態にセット
    set_hands('m123456789 p23 s99', @game.user_player)
    pinzu_1 = @game.current_player.hands.first

    post game_play_command_path(@game, params: { event: 'discard', chosen_hand_id: pinzu_1.id })
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :ron do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_ron
      assert_dom 'button[type=submit]', { text: 'ロン', count: 1 }
      assert_dom 'input[type=hidden][name=?]', 'discarded_tile_id', count: 1
      assert_dom 'input[type=hidden][name=?]', 'ron_player_ids[]', minimum: 1
    end

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :through do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_ron
      assert_dom 'button[type=submit]', { text: 'スルー', count: 1 }
      assert_dom 'input[type=hidden][name=?]', 'discarded_tile_id', count: 1
      assert_dom 'input[type=hidden][name=?]', 'ron_player_ids[]', minimum: 0
    end
  end

  test 'renders ron auto-form (with hidden) when ai can ron' do
    user = @game.user_player
    set_player_turn(@game, user)
    set_hands('p1', user)
    pinzu_1 = user.hands.first

    # 1筒でロン和了できる状態にセット
    ai = @game.ais.sample
    set_hands('m123456789 p23 s99', ai)

    post game_play_command_path(@game, params: { event: 'discard', chosen_hand_id: pinzu_1.id })
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_ron
      assert_dom 'input[type=hidden][name=?]', 'discarded_tile_id', count: 1
      assert_dom 'input[type=hidden][name=?]', 'ron_player_ids[]', minimum: 1
    end

    assert_not_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :ron
    assert_not_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :through
  end

  test 'renders tsumo form when user can tsumo' do
    user = @game.user_player
    set_player_turn(@game, user)

    # 1筒でツモ和了できる状態にセット
    set_hands('m123456789 p23 s99', user)
    set_draw_tile('p1', @game)

    post game_play_command_path(@game, params: { event: 'draw' })
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :tsumo do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_tsumo
      assert_dom 'button[type=submit]', { text: 'ツモ', count: 1 }
      assert_dom 'input[type=hidden][name=?][value=?]', :tsumo, :true
    end

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :pass do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_tsumo
      assert_dom 'button[type=submit]', { text: 'パス', count: 1 }
      assert_dom 'input[type=hidden][name=?][value=?]', :tsumo, :false
    end
  end

  test 'renders tsumo auto-form when ai can tsumo' do
    ai = @game.ais.sample
    set_player_turn(@game, ai)

    # 1筒でツモ和了できる状態にセット
    set_hands('m123456789 p23 s99', ai)
    set_draw_tile('p1', @game)

    post game_play_command_path(@game, params: { event: 'draw' })
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_tsumo
      assert_dom 'input[type=hidden][name=?][value=?]', :tsumo, :true
    end

    assert_not_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :tsumo
    assert_not_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :pass
  end

  test 'renders selectable hands form when user select tsumo_pass' do
    user = @game.user_player
    set_player_turn(@game, user)
    set_hands('m123456789 p123 s99', user)

    post game_play_command_path(@game), params: { event: 'confirm_tsumo', tsumo: :false }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'input[type=radio][name=chosen_hand_id]'
  end

  test 'renders confirm_kan form when user can ankan' do
    user = @game.user_player
    set_player_turn(@game, user)

    # 1筒で暗カンできる状態にセット
    set_hands('m123456789 p111 s9', user)
    set_draw_tile('p1', @game)

    post game_play_command_path(@game), params: { event: 'draw' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    @game.reload
    kan_ids = @game.current_player.ankan_and_kakan_candidates[:ankan].first.grep(Hand).map(&:id)

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :ankan_candidate do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_kan
      assert_dom 'input[type=hidden][name=?][value=?]', :kan, 'true'
      assert_dom 'input[type=hidden][name=?][value=?]', :kan_type, :ankan
      kan_ids.each do |id|
        assert_dom 'input[type=hidden][name=?][value=?]', 'kan_ids[]', id
      end
    end

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :kan_pass do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_kan
      assert_dom 'input[type=hidden][name=?][value=?]', :kan, 'false'
      assert_dom 'button[type=submit]', text: 'パス', count: 1
    end
  end

  test 'renders confirm_kan form when user can kakan' do
    user = @game.user_player
    set_player_turn(@game, user)

    # 1筒でカカンできる状態にセット
    set_hands('m123456789 s9', user)
    set_melds('p111=', user)
    set_draw_tile('p1', @game)

    post game_play_command_path(@game), params: { event: 'draw' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    @game.reload
    kan_ids = @game.current_player.ankan_and_kakan_candidates[:kakan].first.grep(Hand).map(&:id)

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :kakan_candidate do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_kan
      assert_dom 'input[type=hidden][name=?][value=?]', :kan, 'true'
      assert_dom 'input[type=hidden][name=?][value=?]', :kan_type, :kakan
      kan_ids.each do |id|
        assert_dom 'input[type=hidden][name=?][value=?]', 'kan_ids[]', id
      end
    end

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :kan_pass do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_kan
      assert_dom 'input[type=hidden][name=?][value=?]', :kan, 'false'
      assert_dom 'button[type=submit]', text: 'パス', count: 1
    end
  end

  test 'renders auto-form when ai can ankan' do
    ai = @game.ais.first
    set_player_turn(@game, ai)

    # 1筒で暗カンできる状態にセット
    set_hands('m123456789 p111 s9', ai)
    set_draw_tile('p1', @game)

    post game_play_command_path(@game), params: { event: 'draw' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :kan_auto_pass do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_kan
      assert_dom 'input[type=hidden][name=?][value=?]', :kan, 'false'
    end
  end

  test 'kan confirmation transitions next_event to rinshan_draw after accepted' do
    game = start_game(:tonnan)
    player = game.user_player
    set_player_turn(game, player)
    set_hands('m1111 p23456789 z12', player)
    kan_ids = player.hands.select { |h| h.name == '1萬' }.map(&:id)

    post game_play_command_path(game), params: { event: 'confirm_kan', kan: true, kan_type: :ankan, kan_ids: }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :rinshan_draw
    end
  end

  test 'sukantsu triggers ryukyoku' do
    game = start_game(:tonnan)
    player = game.user_player
    set_player_turn(game, player)
    chosen_hand_id = player.hands.first.id
    game.latest_honba.update!(kan_count: Game::MAX_KAN_COUNT)

    post game_play_command_path(game), params: { event: 'discard', chosen_hand_id: }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :ryukyoku
    end
  end

  test 'renders result when someone wins' do
    set_hands('m123456789 p123 s99', @game.host)

    post game_play_command_path(@game), params: { event: 'confirm_tsumo', tsumo: :true }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'h2', text: '対局結果'
  end

  test 'renders next round form when someone wins' do
    set_hands('m123456789 p123 s99', @game.host)

    post game_play_command_path(@game), params: { event: 'confirm_tsumo', tsumo: :true }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?]', game_play_command_path(@game) do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :result
    end
    assert_dom 'input[type=?][value=?]', 'submit', '次へ'
  end

  test 'renders result when ryukyoku' do
    post game_play_command_path(@game), params: { event: 'ryukyoku' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'h2', text: '対局結果'
  end

  test 'advances to next honba when host player tsumo' do
    set_hands('m123456789 p123 s99', @game.host)

    before_honbas_count = @game.latest_round.honbas.count
    before_honba_number = @game.latest_honba.number
    before_step_number  = @game.current_step_number

    assert_dom 'span', text: '東一局'
    assert_dom 'span', text: '〇本場'

    post game_play_command_path(@game), params: { event: 'confirm_tsumo', tsumo: :true }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'result', ryukyoku: :false }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'span', text: '東一局'
    assert_dom 'span', text: '一本場'

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end

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

    post game_play_command_path(@game), params: { event: 'tsumo', tsumo: :true }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'result', ryukyoku: false }
    assert_response :redirect
    follow_redirect!

    assert_dom 'span', text: '東二局'
    assert_dom 'span', text: '〇本場'

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end

    assert_equal before_rounds_count + 1, @game.rounds.count
    assert_equal before_round_number + 1, @game.latest_round.number
    assert_equal 0, @game.current_step_number
  end

  test 'advances to next honba when host player ron' do
    # ホストを1筒でロン和了できる状態にセット
    set_hands('m123456789 p23 s99', @game.host)

    non_host_player = @game.children.sample
    set_player_turn(@game, non_host_player)
    discarded_tile_id = set_hands('p1', non_host_player).first.tile.id

    before_honbas_count = @game.latest_round.honbas.count
    before_honba_number = @game.latest_honba.number
    before_step_number  = @game.current_step_number

    assert_dom 'span', text: '東一局'
    assert_dom 'span', text: '〇本場'

    post game_play_command_path(@game), params: { event: 'confirm_ron', discarded_tile_id:, ron_player_ids: [ @game.host.id ] }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'result', ryukyoku: :false }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'span', text: '東一局'
    assert_dom 'span', text: '一本場'

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end

    assert_equal before_honbas_count + 1, @game.latest_round.honbas.count
    assert_equal before_honba_number + 1, @game.latest_honba.number
    assert_equal 0, @game.current_step_number
  end

  test 'advances to next round when non-host player ron' do
    non_host_player = @game.children.sample
    set_hands('m123456789 p23 s99', non_host_player)
    discarded_tile_id = set_hands('p1', @game.host).first.tile.id

    before_rounds_count = @game.rounds.count
    before_round_number = @game.latest_round.number
    before_step_number  = @game.current_step_number

    assert_dom 'span', text: '東一局'
    assert_dom 'span', text: '〇本場'

    post game_play_command_path(@game, params: { event: 'ron', discarded_tile_id:, ron_player_ids: [ non_host_player.id ] })
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'result', ryukyoku: :false }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'span', text: '東二局'
    assert_dom 'span', text: '〇本場'

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end

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

    post game_play_command_path(@game), params: { event: 'result', ryukyoku: true }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'span', text: '東二局'
    assert_dom 'span', text: '一本場'

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :draw
    end

    assert_equal before_rounds_count + 1, @game.rounds.count
    assert_equal before_round_number + 1, @game.latest_round.number
    assert_equal before_honba_number + 1, @game.latest_honba.number
    assert_equal 0, @game.current_step_number
  end

  test 'result → game_end_event when game is game_end' do
    final_round_number = @game.game_mode.round_count
    @game.latest_round.update!(number: final_round_number)

    # 親がトップでないようにポイントを調整し連荘にならないようにする
    child = @game.children.first
    host = @game.host
    host.game_records.last.update!(point: -1)
    child.game_records.last.update!(point: 1)

    @game.reload
    assert_not @game.host_winner?
    assert @game.game_end?

    post game_play_command_path(@game), params: { event: 'result', ryukyoku: false }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'h2', text: '対局終了'
    assert_dom 'table' do
      assert_dom 'th', text: '順位'
      assert_dom 'th', text: 'プレイヤー'
      assert_dom 'th', text: '最終スコア'
    end

    assert_dom 'a[href=?][data-turbo=?]', home_path, 'false', text: 'ホームに戻る'
  end

  test 'winner result card displays hands, melds, yaku, han and point' do
    winner = @game.user_player
    set_host(@game, winner)
    loser = @game.ais.first
    set_player_turn(@game, loser)

    set_hands('m123456789 p5', winner, drawn: false)
    set_melds('z111=', winner)
    expected_hand_count = winner.hands.count
    expected_meld_count = winner.melds.count
    winning_tile = set_hands('p555', loser).first.tile

    post game_play_command_path(@game), params: { event: 'confirm_ron', discarded_tile_id: winning_tile.id, ron_player_ids: [ winner.id ] }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom %(div[data-player-result-card-id="#{winner.id}"]) do
      winner.hands.each do |hand|
        assert_dom %(div[data-result-card-role="hands"] img[data-result-hand-id="#{hand.id}"])
      end
      winner.melds.each do |meld|
        assert_dom %(div[data-result-card-role="melds"] div[data-result-meld-id="#{meld.id}"])
      end
    end

    winner_statements = winner.score_statements(tile: winning_tile)
    assert_dom 'p', text: "#{winner_statements[:han_total]}飜 #{winner_statements[:fu_total]}符"

    winner_statements[:yaku_list].each do |yaku|
      assert_dom 'li', text: "#{yaku[:name]}（#{yaku[:han]}飜）"
    end

    helpers = ApplicationController.helpers
    point_delta_text = winner.point.positive? ? "+#{helpers.number_with_delimiter(winner.point)}" : helpers.number_with_delimiter(winner.point)
    assert_dom 'p', text: point_delta_text
  end

  test 'host mangan ron updates score: winner player add point and loser player lose point' do
    host = @game.user_player
    set_host(@game, host)

    loser = @game.ais.sample
    set_player_turn(@game, loser)

    # ホストを4筒でロン和了できる状態にセット
    set_hands('m234678 p23 s23488', host, drawn: false)
    pinzu_4 = set_hands('p4', loser).first.tile

    assert_dom %(div[data-player-board-test-id="#{host.id}"]) do
      assert_dom %(span[data-role="score"]), text: '25,000'
    end

    assert_dom %(div[data-player-board-test-id="#{loser.id}"]) do
      assert_dom %(span[data-role="score"]), text: '25,000'
    end

    score_statements = host.score_statements(tile: pinzu_4)
    point = PointCalculator.calculate_point(score_statements, host)

    post game_play_command_path(@game), params: { event: 'confirm_ron', discarded_tile_id: pinzu_4.id, ron_player_ids: [ host.id ] }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'result', ryukyoku: false }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    winner_score = number_with_delimiter(25000 + point[:receiving])
    assert_dom %(div[data-player-board-test-id="#{host.id}"]) do
      assert_dom %(span[data-role="score"]), text: winner_score
    end

    loser_score = number_with_delimiter(25000 + point[:payment])
    assert_dom %(div[data-player-board-test-id="#{loser.id}"]) do
      assert_dom %(span[data-role="score"]), text: loser_score
    end
  end

  test 'host mangan tsumo updates score: tsumo agari player add point and loser other players lose point' do
    host = @game.ais.sample
    set_host(@game, host)
    set_player_turn(@game, host)

    # ホストを4索でツモ和了できる状態にセット
    set_hands('m234678 p234 s22234', host, drawn: true)
    set_rivers('m1', host) # 天和対策（河に捨て牌がない状態でツモすると役満となるため）

    score_statements = host.score_statements
    point = PointCalculator.calculate_point(score_statements, host)

    @game.players.each do |player|
      assert_dom %(div[data-player-board-test-id="#{player.id}"]) do
        assert_dom %(span[data-role="score"]), text: '25,000'
      end
    end

    post game_play_command_path(@game), params: { event: 'confirm_tsumo', tsumo: true }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'result', ryukyoku: false }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    winner_score = number_with_delimiter(25000 + point[:receiving])
    loser_score = number_with_delimiter(25000 + point[:payment][:child])

    @game.players.each do |player|
      assert_dom %(div[data-player-board-test-id="#{player.id}"]) do
        if player.host?
          assert_dom %(span[data-role="score"]), text: winner_score
        else
          assert_dom %(span[data-role="score"]), text: loser_score
        end
      end
    end
  end

  test 'rotates wind when advances next round' do
    ton_wind_player = @game.players[0]
    nan_wind_player = @game.players[1]
    sha_wind_player = @game.players[2]
    pei_wind_player = @game.players[3]

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

    post game_play_command_path(@game), params: { event: 'result', ryukyoku: true }
    assert_response :redirect
    follow_redirect!
    assert_response :success

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

    post game_play_command_path(@game), params: { event: 'draw' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :riichi do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_riichi
      assert_dom 'button[type=submit]', { text: 'リーチ', count: 1 }
    end

    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :pass do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_riichi
      assert_dom 'button[type=submit]', { text: 'パス', count: 1 }
    end
  end

  test 'auto-submit riichi when ai is menzen tenpai' do
    ai = @game.ais.sample
    set_player_turn(@game, ai)
    set_hands('m123456789 p2 s11 z1', ai)
    set_draw_tile('p3', @game)

    post game_play_command_path(@game), params: { event: 'draw' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :confirm_riichi
    end

    assert_not_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :riichi
    assert_not_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :pass
  end

  test 'user can select only riichi candidates when riichi' do
    user = @game.user_player
    set_player_turn(@game, user)
    set_hands('m123456789 p23 s11 z1', user)

    post game_play_command_path(@game), params: { event: 'confirm_riichi', riichi: true }
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

    # 東（z1）切りでリーチできる状態にセット
    set_hands('m123456789 p23 s11 z1', ai)
    riichi_candidate = ai.hands.last

    post game_play_command_path(@game), params: { event: 'confirm_riichi', riichi: true }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :choose_riichi
      assert_dom 'input[type=hidden][name=?]', 'riichi_candidate_ids[]'
    end

    post game_play_command_path(@game), params: { event: 'choose_riichi', riichi_candidate_ids: [ riichi_candidate.id ] }
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

    post game_play_command_path(@game), params: { event: 'draw' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :tsumogiri
    end

    post game_play_command_path(@game), params: { event: 'tsumogiri' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    @game.reload
    drawn_hand_id = @game.current_player.hands.find(&:drawn).id.to_s

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :discard
      assert_dom 'input[type=hidden][name=?][value=?]', 'chosen_hand_id', drawn_hand_id
    end
  end

  test 'riichi player is passes tsumo moves to tsumogiri event' do
    user = @game.user_player
    set_player_turn(@game, user)
    set_hands('m123456789 p111 s11', user, drawn: false)
    user.current_state.update!(riichi: true)

    post game_play_command_path(@game), params: { event: 'confirm_tsumo', tsumo: false }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_dom 'form[action=?][data-controller=?]', game_play_command_path(@game), 'auto-submit' do
      assert_dom 'input[type=hidden][name=?][value=?]', :event, :tsumogiri
    end
  end

  test 'furiten flow：自分の捨て牌に和了牌があるとフリテンとなりロンができない' do
    user = @game.user_player
    ai = @game.ais.first

    set_hands('m12345678 p123 s11', user, drawn: false) # 369萬待ち
    set_rivers('m3', user) # 3萬を自分で切っている（フリテン）

    set_player_turn(@game, ai)
    manzu_9_a = set_hands('m999', ai).first

    post game_play_command_path(@game), params: { event: 'discard', chosen_hand_id: manzu_9_a.id }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # 9萬は和了牌であるが、フリテンのためronイベントは発火されない。
    assert_not_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :ron
  end

  test 'furiten flow：和了牌が鳴かれて自分の河にない状態であるが、フリテンの判定となる' do
    user = @game.user_player
    ai_1 = @game.ais.first
    ai_2 = @game.ais.second
    ai_3 = @game.ais.last

    # 平和の369萬待ち
    set_hands('m12345678 p123 s11', user, drawn: false)
    set_rivers('m3', user, stolen: true) # 3萬を自分で切っているが他のプレイヤーから泣かれて自分の河にない状態（フリテン）

    set_player_turn(@game, ai_1)
    manzu_9 = set_hands('m99', ai_1).first

    post game_play_command_path(@game), params: { event: 'discard', chosen_hand_id: manzu_9.id }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # 9萬は和了牌かつ自分の河にない状態であるが、フリテンのためronイベントは発火しない。
    assert_not_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :ron
  end

  test 'furiten flow：1枚目の和了牌はロン可能、同じ順目の2枚目以降の和了牌はロン不可、1巡後、牌を切った後は同順内フリテンが解消されロン可能となる' do
    user = @game.user_player
    ai_1 = @game.ais.first
    ai_2 = @game.ais.second
    ai_3 = @game.ais.last

    # 平和の369萬待ち
    set_hands('m12345678 p123 s11', user, drawn: false)

    set_player_turn(@game, ai_1)
    manzu_9 = set_hands('m99', ai_1).first

    post game_play_command_path(@game), params: { event: 'discard', chosen_hand_id: manzu_9.id }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # 9萬は和了牌のため、ronイベントが発火されるが見逃す。（同順内フリテンの状態）
    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :ron

    @game.reload
    set_player_turn(@game, ai_2)
    manzu_6 = set_hands('m66', ai_2).last

    # 他のプレイヤーが同じ和了牌を切る。
    post game_play_command_path(@game), params: { event: 'discard', chosen_hand_id: manzu_6.id }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # 和了牌を一度、見逃しているためronイベントが発火されない。
    assert_not_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :ron

    @game.reload
    set_player_turn(@game, user)
    hands = set_hands('m12345678 p123 s11 z1', user, drawn: false) # 手番となり東を引いた状態
    ton = hands.last

    # userが東を切り、同順内フリテンが解消される。
    post game_play_command_path(@game), params: { event: 'discard', chosen_hand_id: ton.id }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    @game.reload
    set_player_turn(@game, ai_3)
    manzu_3 = set_hands('m33', ai_3).last

    # 他のプレイヤーが和了牌を切る。
    post game_play_command_path(@game), params: { event: 'discard', chosen_hand_id: manzu_3.id }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # 同順内フリテンが解消されronイベントが発火される。
    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :ron
  end

  test 'furiten flow：リーチ後に和了牌を見逃すとそれ以降ロンできない' do
    user = @game.user_player
    ai_1 = @game.ais.first
    ai_2 = @game.ais.second
    ai_3 = @game.ais.last

    # 平和の369萬待ち
    set_hands('m12345678 p123 s11', user, drawn: false)
    set_rivers('z1', user)
    user.current_state.update!(riichi: true) # 東を切ってリーチ

    set_player_turn(@game, ai_1)
    manzu_9 = set_hands('m99', ai_1).first

    post game_play_command_path(@game), params: { event: 'discard', chosen_hand_id: manzu_9.id }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # 9萬は和了牌のため、ronイベントが発火されるが見逃す。
    assert_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :ron

    @game.reload
    set_player_turn(@game, ai_2)
    manzu_6 = set_hands('m66', ai_2).last

    # 他のプレイヤーが同じ和了牌を切る。
    post game_play_command_path(@game), params: { event: 'discard', chosen_hand_id: manzu_6.id }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # 和了牌を一度、見逃しているためronイベントが発火されない。
    assert_not_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :ron

    @game.reload
    set_player_turn(@game, user)
    hands = set_hands('m12345678 p123 s11 z1', user, drawn: false) # 手番となり東を引いた状態
    ton = hands.last

    # userが東を切り、同順内フリテンは解消される。
    post game_play_command_path(@game), params: { event: 'discard', chosen_hand_id: ton.id }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    @game.reload
    set_player_turn(@game, ai_3)
    manzu_3 = set_hands('m33', ai_3).last

    # 他のプレイヤーが和了牌を切る。
    post game_play_command_path(@game), params: { event: 'discard', chosen_hand_id: manzu_3.id }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    post game_play_command_path(@game), params: { event: 'switch_event' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # 同順内フリテンが解消されたが、リーチ後に和了牌を見逃しているため、ronイベントは発火されない。
    assert_not_dom 'form[action=?][data-testid=?]', game_play_command_path(@game), :ron
  end
end

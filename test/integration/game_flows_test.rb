# frozen_string_literal: true

require 'test_helper'
require 'helpers/game_test_helper'

class GameFlowsTest < ActionDispatch::IntegrationTest
  include GameTestHelper

  def setup
    post '/guest_login'
    post games_path, params: { game_mode_id: game_modes(:training_mode).id }
    @game = find_game_from_url
    follow_redirect!
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
end

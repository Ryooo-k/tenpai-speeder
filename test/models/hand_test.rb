# frozen_string_literal: true

require 'test_helper'

class HandTest < ActiveSupport::TestCase
  test 'is valid with player_state and tile' do
    player_1_state = player_states(:ryo)
    manzu_1 = tiles(:first_manzu_1)
    hand = Hand.new(player_state: player_1_state, tile: manzu_1)
    assert hand.valid?
  end

  test 'is invalid without player_state' do
    manzu_1 = tiles(:first_manzu_1)
    hand = Hand.new(tile: manzu_1)
    assert hand.invalid?
  end

  test 'is invalid without tile' do
    player_1_state = player_states(:ryo)
    hand = Hand.new(player_state: player_1_state)
    assert hand.invalid?
  end

  test 'drawn default to false' do
    manzu_1 = tiles(:first_manzu_1)
    hand = Hand.new(tile: manzu_1)
    assert_equal false, hand.drawn
  end

  test '.sorted' do
    state = players(:ryo).player_states.last
    hand_1 = state.hands.create!(tile: tiles(:first_manzu_1), drawn: true)
    hand_2 = state.hands.create!(tile: tiles(:first_manzu_2), drawn: false)
    hand_second_3 = state.hands.create!(tile: tiles(:second_manzu_3), drawn: false)
    hand_first_3 = state.hands.create!(tile: tiles(:first_manzu_3), drawn: false)
    assert_equal [ hand_2, hand_first_3, hand_second_3, hand_1 ], state.hands.sorted
  end
end

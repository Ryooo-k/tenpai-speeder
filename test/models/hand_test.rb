# frozen_string_literal: true

require 'test_helper'

class HandTest < ActiveSupport::TestCase
  def setup
    @manzu_1 = tiles(:first_manzu_1)
  end

  test 'drawn default to false' do
    hand = Hand.new(tile: @manzu_1)
    assert_equal false, hand.drawn
  end

  test 'rinshan default to false' do
    hand = Hand.new(tile: @manzu_1)
    assert_equal false, hand.rinshan
  end

  test '.sorted_base orders by tile ASC (ties by id)' do
    state = players(:ryo).current_state
    manzu_1 = state.hands.create!(tile: tiles(:first_manzu_1), drawn: true)
    manzu_2 = state.hands.create!(tile: tiles(:first_manzu_2))
    manzu_3_b = state.hands.create!(tile: tiles(:second_manzu_3))
    manzu_3_a = state.hands.create!(tile: tiles(:first_manzu_3))
    assert_equal [ manzu_1, manzu_2, manzu_3_a, manzu_3_b ], state.hands.sorted_base
  end

  test '.sorted_with_drawn orders by drawn ASC then tile ASC (ties by id)' do
    state = players(:ryo).current_state
    drawn_tile = state.hands.create!(tile: tiles(:first_manzu_1), drawn: true)
    manzu_2 = state.hands.create!(tile: tiles(:first_manzu_2))
    manzu_3_b = state.hands.create!(tile: tiles(:second_manzu_3))
    manzu_3_a = state.hands.create!(tile: tiles(:first_manzu_3))
    assert_equal [ manzu_2, manzu_3_a, manzu_3_b, drawn_tile ], state.hands.sorted_with_drawn
  end
end

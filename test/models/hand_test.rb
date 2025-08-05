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
end

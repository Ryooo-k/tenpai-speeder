# frozen_string_literal: true

require 'test_helper'

class MeldTest < ActiveSupport::TestCase
  def setup
    @state = player_states(:ryo)
  end

  test 'is valid with player_state and tile and kind and number' do
    manzu_1 = tiles(:first_manzu_1)
    meld = Meld.new(player_state: @state, tile: manzu_1, kind: :pon, number: 0)
    assert meld.valid?
  end

  test 'is invalid without player_state' do
    manzu_1 = tiles(:first_manzu_1)
    meld = Meld.new(tile: manzu_1, kind: :pon, number: 0)
    assert meld.invalid?
  end

  test 'is invalid without tile' do
    meld = Meld.new(player_state: @state, kind: :pon, number: 0)
    assert meld.invalid?
  end

  test 'is invalid without kind' do
    manzu_1 = tiles(:first_manzu_1)
    meld = Meld.new(player_state: @state, tile: manzu_1, number: 0)
    assert meld.invalid?
  end

  test 'is invalid without number' do
    manzu_1 = tiles(:first_manzu_1)
    meld = Meld.new(player_state: @state, tile: manzu_1, kind: :pon)
    assert meld.invalid?
  end

  test '.ordered sorts by player_state_id desc and number asc' do
    player = players(:ryo)
    state_1 = player.player_states.create!(player:, step: steps(:step_1))
    state_2 = player.player_states.create!(player:, step: steps(:step_2))
    state_1_meld_0 = Meld.create!(player_state: state_1, tile: tiles(:first_manzu_1), kind: :chi, number: 0)
    state_1_meld_1 = Meld.create!(player_state: state_1, tile: tiles(:first_manzu_2), kind: :chi, number: 1)
    state_1_meld_2 = Meld.create!(player_state: state_1, tile: tiles(:first_manzu_3), kind: :chi, number: 2)
    state_2_meld_0 = Meld.create!(player_state: state_2, tile: tiles(:first_manzu_1), kind: :chi, number: 0)
    state_2_meld_1 = Meld.create!(player_state: state_2, tile: tiles(:first_manzu_2), kind: :chi, number: 1)
    state_2_meld_2 = Meld.create!(player_state: state_2, tile: tiles(:first_manzu_3), kind: :chi, number: 2)
    assert_equal [ state_2_meld_0, state_2_meld_1, state_2_meld_2, state_1_meld_0, state_1_meld_1, state_1_meld_2 ], Meld.all.sorted.to_a
  end
end

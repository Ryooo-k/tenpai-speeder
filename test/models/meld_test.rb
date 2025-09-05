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

  test '.ordered orders number' do
    @state.melds.delete_all
    third_meld = @state.melds.create!(tile: tiles(:first_manzu_3), kind: :chi, number: 2)
    second_meld = @state.melds.create!(tile: tiles(:first_manzu_2), kind: :chi, number: 1)
    first_meld = @state.melds.create!(tile: tiles(:first_manzu_1), kind: :chi, number: 0)
    assert_equal [ first_meld, second_meld, third_meld ], @state.melds.ordered
  end
end

# frozen_string_literal: true

require 'test_helper'

class MeldTest < ActiveSupport::TestCase
  test 'is valid with player_state and tile and kind' do
    player_state = player_states(:ryo)
    manzu_1 = tiles(:first_manzu_1)
    meld = Meld.new(player_state:, tile: manzu_1, kind: :pon)
    assert meld.valid?
  end

  test 'is invalid without player_state' do
    manzu_1 = tiles(:first_manzu_1)
    meld = Meld.new(tile: manzu_1, kind: :pon)
    assert meld.invalid?
  end

  test 'is invalid without tile' do
    player_state = player_states(:ryo)
    meld = Meld.new(player_state:, kind: :pon)
    assert meld.invalid?
  end

  test 'is invalid without kind' do
    player_state = player_states(:ryo)
    manzu_1 = tiles(:first_manzu_1)
    meld = Meld.new(player_state:, tile: manzu_1)
    assert meld.invalid?
  end
end

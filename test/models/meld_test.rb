# frozen_string_literal: true

require 'test_helper'

class MeldTest < ActiveSupport::TestCase
  test 'is valid with player_state and tile and pon action' do
    player_state = player_states(:ryo_step_1)
    manzu_1 = tiles(:first_manzu_1)
    action = actions(:pon)
    meld = Meld.new(player_state:, tile: manzu_1, action:)
    assert meld.valid?
  end

  test 'is invalid without player_state' do
    manzu_1 = tiles(:first_manzu_1)
    action = actions(:pon)
    meld = Meld.new(tile: manzu_1, action:)
    assert meld.invalid?
  end

  test 'is invalid without tile' do
    player_state = player_states(:ryo_step_1)
    action = actions(:pon)
    meld = Meld.new(player_state:, action:)
    assert meld.invalid?
  end

  test 'validate_action_type' do
    player_state = player_states(:ryo_step_1)
    tile = tiles(:first_manzu_1)

    chi = actions(:chi)
    meld = Meld.new(player_state:, tile:, action: chi)
    assert meld.valid?

    daiminkan = actions(:daiminkan)
    meld = Meld.new(player_state:, tile:, action: daiminkan)
    assert meld.valid?

    kakan = actions(:kakan)
    meld = Meld.new(player_state:, tile:, action: kakan)
    assert meld.valid?

    ankan = actions(:ankan)
    meld = Meld.new(player_state:, tile:, action: ankan)
    assert meld.valid?

    draw = actions(:draw)
    meld = Meld.new(player_state:, tile:, action: draw)
    assert meld.invalid?
    assert_includes meld.errors[:action], 'drawは許可されていません'

    discard = actions(:discard)
    meld = Meld.new(player_state:, tile:, action: discard)
    assert meld.invalid?
    assert_includes meld.errors[:action], 'discardは許可されていません'

    riichi = actions(:riichi)
    meld = Meld.new(player_state:, tile:, action: riichi)
    assert meld.invalid?
    assert_includes meld.errors[:action], 'riichiは許可されていません'

    tsumo = actions(:tsumo)
    meld = Meld.new(player_state:, tile:, action: tsumo)
    assert meld.invalid?
    assert_includes meld.errors[:action], 'tsumoは許可されていません'

    ron = actions(:ron)
    meld = Meld.new(player_state:, tile:, action: ron)
    assert meld.invalid?
    assert_includes meld.errors[:action], 'ronは許可されていません'

    pass = actions(:pass)
    meld = Meld.new(player_state:, tile:, action: pass)
    assert meld.invalid?
    assert_includes meld.errors[:action], 'passは許可されていません'
  end
end

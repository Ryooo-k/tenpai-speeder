# frozen_string_literal: true

require 'test_helper'

class RiverTest < ActiveSupport::TestCase
  test 'is valid with tsumogiri and player_state and tile' do
    player_state = player_states(:ryo_step_1)
    tile = tiles(:first_manzu_1)
    river = River.new(player_state:, tile:, tsumogiri: false)
    assert river.valid?
  end

  test 'is invalid without tsumogiri' do
    player_state = player_states(:ryo_step_1)
    tile = tiles(:first_manzu_1)
    river = River.new(player_state:, tile:)
    assert river.invalid?
  end

  test 'is invalid without player_state' do
    tile = tiles(:first_manzu_1)
    river = River.new(tile:, tsumogiri: false)
    assert river.invalid?
  end

  test 'is invalid without tile' do
    player_state = player_states(:ryo_step_1)
    river = River.new(player_state:, tsumogiri: false)
    assert river.invalid?
  end

  test 'tsumogiri must be true or false' do
    player_state = player_states(:ryo_step_1)
    tile = tiles(:first_manzu_1)
    river = River.new(player_state:, tile:, tsumogiri: nil)
    assert river.invalid?

    river = River.new(player_state:, tile:, tsumogiri: true)
    assert river.valid?
  end
end

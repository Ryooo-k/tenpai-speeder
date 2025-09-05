# frozen_string_literal: true

require 'test_helper'

class RiverTest < ActiveSupport::TestCase
  def setup
    @state = player_states(:ryo)
    @manzu_1 = tiles(:first_manzu_1)
    @manzu_2 = tiles(:first_manzu_2)
    @manzu_3 = tiles(:first_manzu_3)
  end

  test 'is valid with tsumogiri and player_state and tile' do
    river = River.new(player_state: @state, tile: @manzu_1, tsumogiri: false)
    assert river.valid?
  end

  test 'is invalid without tsumogiri' do
    river = River.new(player_state: @state, tile: @manzu_1)
    assert river.invalid?
  end

  test 'is invalid without player_state' do
    river = River.new(tile: @manzu_1, tsumogiri: false)
    assert river.invalid?
  end

  test 'is invalid without tile' do
    river = River.new(player_state: @state, tsumogiri: false)
    assert river.invalid?
  end

  test 'tsumogiri must be true or false' do
    river = River.new(player_state: @state, tile: @manzu_1, tsumogiri: nil)
    assert river.invalid?

    river = River.new(player_state: @state, tile: @manzu_1, tsumogiri: true)
    assert river.valid?
  end

  test 'called default to false' do
    river = River.new(player_state: @state, tile: @manzu_1, tsumogiri: false)
    assert_not river.called
  end

  test '.ordered' do
    @state.rivers.delete_all
    first_river = @state.rivers.create!(tile: @manzu_3, tsumogiri: false)
    second_river = @state.rivers.create!(tile: @manzu_1, tsumogiri: false)
    third_river = @state.rivers.create!(tile: @manzu_2, tsumogiri: false)
    assert_equal [ first_river, second_river, third_river ], @state.rivers.ordered
  end
end

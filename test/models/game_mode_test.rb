# frozen_string_literal: true

require 'test_helper'

class GameModeTest < ActiveSupport::TestCase
  def setup
    @name = 'トレーニング'
    @description = '練習モードです。'
    @round_count = 0
    @mode_type = 0
  end

  test 'is valid with name and description and round_count and mode_type' do
    game_mode = GameMode.new(name: @name, description: @description, round_count: @round_count, mode_type: @mode_type)
    assert game_mode.valid?
  end

  test 'is invalid without name' do
    game_mode = GameMode.new(description: @description, round_count: @round_count, mode_type: @mode_type)
    assert game_mode.invalid?
  end

  test 'is invalid without description' do
    game_mode = GameMode.new(name: @name, round_count: @round_count, mode_type: @mode_type)
    assert game_mode.invalid?
  end

  test 'is invalid without round_count' do
    game_mode = GameMode.new(name: @name, description: @description, mode_type: @mode_type)
    assert game_mode.invalid?
  end

  test 'is invalid without mode_type' do
    game_mode = GameMode.new(name: @name, description: @description, round_count: @round_count)
    assert game_mode.invalid?
  end
end

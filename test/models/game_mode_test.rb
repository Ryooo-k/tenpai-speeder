# frozen_string_literal: true

require 'test_helper'

class GameModeTest < ActiveSupport::TestCase
  def setup
    @name = 'トレーニング'
    @description = '練習モードです。'
    @round_type = 0 # １局戦
    @mode_type = 0 # training
  end

  test 'is valid with name and description and round_type and mode_type' do
    game_mode = GameMode.new(name: @name, description: @description, round_type: @round_type, mode_type: @mode_type)
    assert game_mode.valid?
  end

  test 'is invalid without name' do
    game_mode = GameMode.new(description: @description, round_type: @round_type, mode_type: @mode_type)
    assert game_mode.invalid?
  end

  test 'is invalid without description' do
    game_mode = GameMode.new(name: @name, round_type: @round_type, mode_type: @mode_type)
    assert game_mode.invalid?
  end

  test 'is invalid without round_type' do
    game_mode = GameMode.new(name: @name, description: @description, mode_type: @mode_type)
    assert game_mode.invalid?
  end

  test 'is invalid without mode_type' do
    game_mode = GameMode.new(name: @name, description: @description, round_type: @round_type)
    assert game_mode.invalid?
  end

  test 'aka_dora default to true' do
    game_mode = GameMode.new(name: @name, description: @description, round_type: @round_type, mode_type: @mode_type)
    assert game_mode.aka_dora?
  end
end

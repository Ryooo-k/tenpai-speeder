# frozen_string_literal: true

require 'test_helper'

class GameModeTest < ActiveSupport::TestCase
  test 'is invalid without mode_type' do
    game_mode = GameMode.new
    assert game_mode.invalid?
  end
end

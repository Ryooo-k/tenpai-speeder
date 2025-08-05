# frozen_string_literal: true

require 'test_helper'

class ScoreTest < ActiveSupport::TestCase
  def setup
    @player = players(:ryo)
    @honba = honbas(:ton_1_kyoku_0_honba)
  end

  test 'is valid with player' do
    score = Score.new(player: @player)
    assert score.valid?
  end

  test 'is invalid without player' do
    score = Score.new
    assert score.invalid?
  end

  test 'score default to 25_000' do
    score = Score.new(player: @player, honba: @honba)
    assert_equal 25_000, score.score
  end
end

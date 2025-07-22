# frozen_string_literal: true

require 'test_helper'

class ScoreTest < ActiveSupport::TestCase
  test 'is valid with score and player and honba' do
    player = players(:ryo)
    honba = honbas(:ton_1_kyoku_0_honba)
    score = Score.new(player:, honba:, score: 25_000)
    assert score.valid?
  end

  test 'is invalid without score' do
    player = players(:ryo)
    honba = honbas(:ton_1_kyoku_0_honba)
    score = Score.new(player:, honba:)
    assert score.invalid?
  end

  test 'is invalid without player' do
    honba = honbas(:ton_1_kyoku_0_honba)
    score = Score.new(honba:, score: 25_000)
    assert score.invalid?
  end

  test 'is invalid without honba' do
    player = players(:ryo)
    score = Score.new(player:, score: 25_000)
    assert score.invalid?
  end
end

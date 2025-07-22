# frozen_string_literal: true

require 'test_helper'

class ResultTest < ActiveSupport::TestCase
  test 'is valid with score and rank and game and player' do
    player = players(:ryo)
    game = games(:tonpuu)
    result = Result.new(player:, game:, score: 25_000, rank: 1)
    assert result.valid?
  end

  test 'is invalid without score' do
    player = players(:ryo)
    game = games(:tonpuu)
    result = Result.new(player:, game:, rank: 1)
    assert result.invalid?
  end

  test 'is invalid without rank' do
    player = players(:ryo)
    game = games(:tonpuu)
    result = Result.new(player:, game:, score: 25_000)
    assert result.invalid?
  end

  test 'is invalid without player' do
    game = games(:tonpuu)
    result = Result.new(game:, score: 25_000, rank: 1)
    assert result.invalid?
  end

  test 'is invalid without game' do
    player = players(:ryo)
    result = Result.new(player:, score: 25_000, rank: 1)
    assert result.invalid?
  end
end

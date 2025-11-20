# frozen_string_literal: true

require 'test_helper'

class GameRecordTest < ActiveSupport::TestCase
  def setup
    @player = players(:ryo)
  end

  test 'is valid with player' do
    record = GameRecord.new(player: @player)
    assert record.valid?
  end

  test 'is invalid without player' do
    record = GameRecord.new
    assert record.invalid?
  end

  test 'score default to 25_000' do
    record = GameRecord.new(player: @player, honba: honbas(:honba_0))
    assert_equal 25_000, record.score
  end

  test 'point default to 0' do
    record = GameRecord.new(player: @player, honba: honbas(:honba_0))
    assert_equal 0, record.point
  end
end

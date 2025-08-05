# frozen_string_literal: true

require 'test_helper'

class GameRecordTest < ActiveSupport::TestCase
  def setup
    @player = players(:ryo)
    @honba = honbas(:ton_1_kyoku_0_honba)
  end

  test 'is valid with player' do
    record = GameRecord.new(player: @player)
    assert record.valid?
  end

  test 'is invalid without player' do
    record = GameRecord.new
    assert record.invalid?
  end

  test 'record default to 25_000' do
    record = GameRecord.new(player: @player, honba: @honba)
    assert_equal 25_000, record.score
  end
end

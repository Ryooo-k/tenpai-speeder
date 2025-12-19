# frozen_string_literal: true

require 'test_helper'

class GameRecordTest < ActiveSupport::TestCase
  def setup
    @player = players(:ryo)
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

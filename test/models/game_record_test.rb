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

  test '.ordered orders by honba_id asc' do
    @player.game_records.delete_all
    game = games(:training)
    ton_1 = game.rounds.create!(number: 0)
    ton_1_honba_0 = ton_1.honbas.create!(number: 0)
    ton_1_honba_1 = ton_1.honbas.create!(number: 1)
    record_2 = @player.game_records.create!(honba: ton_1_honba_1)
    record_1 = @player.game_records.create!(honba: ton_1_honba_0)
    assert_equal [ record_1, record_2 ], @player.game_records.ordered.to_a

    ton_2 = game.rounds.create!(number: 1)
    ton_2_honba_0 = ton_2.honbas.create!(number: 0)
    ton_2_honba_1 = ton_2.honbas.create!(number: 1)
    record_4 = @player.game_records.create!(honba: ton_2_honba_1)
    record_3 = @player.game_records.create!(honba: ton_2_honba_0)
    assert_equal [ record_1, record_2, record_3, record_4 ], @player.game_records.ordered
  end
end

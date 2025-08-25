# frozen_string_literal: true

require 'test_helper'

class RoundTest < ActiveSupport::TestCase
  def setup
    @round = rounds(:ton_1_kyoku)
  end

  test 'destroying round should also destroy honbas' do
    assert_difference('Honba.count', -@round.honbas.count) do
      @round.destroy
    end
  end

  test 'is valid with game' do
    round = Round.new(game: games(:tonpuu))
    assert round.valid?
  end

  test 'is invalid without game' do
    round = Round.new
    assert round.invalid?
  end

  test 'number default to 0' do
    round = Round.new(game: games(:tonpuu))
    assert_equal 0, round.number
  end

  test 'host_position default to 0' do
    round = Round.new(game: games(:tonpuu))
    assert_equal 0, round.host_position
  end

  test 'create first honba when after_create calls create_step' do
    round = Round.new(game: games(:tonpuu))
    assert_equal 0, round.honbas.count
    round.save
    assert_equal 1, round.honbas.count
  end

  test '#current_honba' do
    max_number = @round.honbas.maximum(:number)
    expected = @round.honbas.find_by(number: max_number)
    assert_equal expected, @round.current_honba
  end
end

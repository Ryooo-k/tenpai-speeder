# frozen_string_literal: true

require 'test_helper'

class RoundTest < ActiveSupport::TestCase
  def setup
    @round = rounds(:ton_1)
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

  test 'create first honba when after_create calls create_step' do
    round = Round.new(game: games(:tonpuu))
    assert_equal 0, round.honbas.count
    round.save
    assert_equal 1, round.honbas.count
  end

  test '#latest_honba' do
    max_number = @round.honbas.maximum(:number)
    expected = @round.honbas.find_by(number: max_number)
    assert_equal expected, @round.latest_honba
  end

  test '#name' do
    @round.number = 0
    assert_equal '東一局', @round.name
    @round.number = 1
    assert_equal '東二局', @round.name
    @round.number = 2
    assert_equal '東三局', @round.name
    @round.number = 3
    assert_equal '東四局', @round.name
    @round.number = 4
    assert_equal '南一局', @round.name
    @round.number = 5
    assert_equal '南二局', @round.name
    @round.number = 6
    assert_equal '南三局', @round.name
    @round.number = 7
    assert_equal '南四局', @round.name
  end

  test '#host_seat_number' do
    @round.number = 0
    assert_equal 0, @round.host_seat_number
    @round.number = 1
    assert_equal 1, @round.host_seat_number
    @round.number = 2
    assert_equal 2, @round.host_seat_number
    @round.number = 3
    assert_equal 3, @round.host_seat_number
    @round.number = 4
    assert_equal 0, @round.host_seat_number
    @round.number = 5
    assert_equal 1, @round.host_seat_number
    @round.number = 6
    assert_equal 2, @round.host_seat_number
    @round.number = 7
    assert_equal 3, @round.host_seat_number
  end

  test '#wind_number' do
    @round.number = 0
    assert_equal 0, @round.wind_number
    @round.number = 1
    assert_equal 0, @round.wind_number
    @round.number = 2
    assert_equal 0, @round.wind_number
    @round.number = 3
    assert_equal 0, @round.wind_number
    @round.number = 4
    assert_equal 1, @round.wind_number
    @round.number = 5
    assert_equal 1, @round.wind_number
    @round.number = 6
    assert_equal 1, @round.wind_number
    @round.number = 7
    assert_equal 1, @round.wind_number
  end
end

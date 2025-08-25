# frozen_string_literal: true

require 'test_helper'

class TurnTest < ActiveSupport::TestCase
  def setup
    @turn = turns(:turn_1)
  end

  test 'destroying turn should also destroy steps' do
    assert_difference('Step.count', -@turn.steps.count) do
      @turn.destroy
    end
  end

  test 'is valid with honba' do
    turn = Turn.new(honba: honbas(:ton_1_kyoku_0_honba))
    assert turn.valid?
  end

  test 'is invalid without honba' do
    turn = Turn.new
    assert turn.invalid?
  end

  test 'number default to 0' do
    turn = Turn.new(honba: honbas(:ton_1_kyoku_0_honba))
    assert_equal 0, turn.number
  end

  test 'create first step when after_create calls create_step' do
    turn = Turn.new(honba: honbas(:ton_1_kyoku_0_honba))
    assert_equal 0, turn.steps.count
    turn.save
    assert_equal 1, turn.steps.count
  end

  test '#current_step' do
    max_number = @turn.steps.maximum(:number)
    max_number_step = @turn.steps.find_by(number: max_number)
    assert_equal max_number_step, @turn.current_step
  end
end

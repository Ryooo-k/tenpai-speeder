# frozen_string_literal: true

require 'test_helper'

class PointCalculatorTest < ActiveSupport::TestCase
  def setup
    game = games(:tonnan)
    @host = game.host
    @child = game.ais.sample
  end

  test '親 1飜30符 ツモ和了：500オール' do
    score_statements = {
      tsumo: true,
      fu_total: 30,
      han_total: 1
    }
    point = PointCalculator.calculate_point(score_statements, @host)

    assert_equal 1500, point[:receiving]
    assert_equal -500, point[:payment][:child]
    assert_equal    0, point[:payment][:host]
  end

  test '親 12飜30符 ツモ和了：12000オール' do
    score_statements = {
      tsumo: true,
      fu_total: 30,
      han_total: 12
    }
    point = PointCalculator.calculate_point(score_statements, @host)

    assert_equal 36000, point[:receiving]
    assert_equal -12000, point[:payment][:child]
    assert_equal      0, point[:payment][:host]
  end

  test '親 26飜 ツモ和了：13飜以上は役満の点数を返す' do
    score_statements = {
      tsumo: true,
      fu_total: 20,
      han_total: 26
    }
    point = PointCalculator.calculate_point(score_statements, @host)
    assert_equal 48000, point[:receiving]
    assert_equal -16000, point[:payment][:child]
    assert_equal      0, point[:payment][:host]
  end

  test '親 1飜20符 ツモ和了：存在しないスコアのためnilを返す' do
    score_statements = {
      tsumo: true,
      fu_total: 20,
      han_total: 1
    }
    point = PointCalculator.calculate_point(score_statements, @host)
    assert_nil point
  end

  test '親 2飜25符 ツモ和了：存在しないスコアのためnilを返す' do
    score_statements = {
      tsumo: true,
      fu_total: 25,
      han_total: 2
    }
    point = PointCalculator.calculate_point(score_statements, @host)
    assert_nil point
  end

  test '親 2飜25符 ロン和了：2400点の受け渡し' do
    score_statements = {
      tsumo: false,
      fu_total: 25,
      han_total: 2
    }
    point = PointCalculator.calculate_point(score_statements, @host)

    assert_equal  2400, point[:receiving]
    assert_equal -2400, point[:payment]
  end

  test '親 2飜110符 ロン和了：10600点の受け渡し' do
    score_statements = {
      tsumo: false,
      fu_total: 110,
      han_total: 2
    }
    point = PointCalculator.calculate_point(score_statements, @host)

    assert_equal  10600, point[:receiving]
    assert_equal -10600, point[:payment]
  end

  test '子 1飜30符 ツモ和了：300 * 2 + 500' do
    score_statements = {
      tsumo: true,
      fu_total: 30,
      han_total: 1
    }
    point = PointCalculator.calculate_point(score_statements, @child)

    assert_equal 1100, point[:receiving]
    assert_equal -300, point[:payment][:child]
    assert_equal -500, point[:payment][:host]
  end

  test '子 13飜30符 ロン和了：32000点の受け渡し' do
    score_statements = {
      tsumo: false,
      fu_total: 30,
      han_total: 13
    }
    point = PointCalculator.calculate_point(score_statements, @child)

    assert_equal  32000, point[:receiving]
    assert_equal -32000, point[:payment]
  end
end

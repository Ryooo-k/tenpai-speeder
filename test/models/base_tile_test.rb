# frozen_string_literal: true

require 'test_helper'

class BaseTileTest < ActiveSupport::TestCase
  test 'is valid with suit and number and name and code' do
    base_tile = BaseTile.new(suit:0, number: 1, name: '1萬', code: 0)
    assert base_tile.valid?
  end

  test 'is invalid without suit' do
    base_tile = BaseTile.new(number: 1, name: '1萬', code: 0)
    assert base_tile.invalid?
  end

  test 'is invalid without number' do
    base_tile = BaseTile.new(suit: 0, name: '1萬', code: 0)
    assert base_tile.invalid?
  end

  test 'is invalid without name' do
    base_tile = BaseTile.new(suit: 0, number: 1, code: 0)
    assert base_tile.invalid?
  end

  test 'is invalid without code' do
    base_tile = BaseTile.new(suit: 0, number: 1, name: '1萬')
    assert base_tile.invalid?
  end

  test 'is invalid if number is not between 1 and 9' do
    base_tile = BaseTile.new(suit: 0, number: 0, name: '1萬')
    assert base_tile.invalid?
  end
end

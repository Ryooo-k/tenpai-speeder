# frozen_string_literal: true

require 'test_helper'

class RuleTest < ActiveSupport::TestCase
  test 'is valid with aka_dora and round_type' do
    rule = Rule.new(aka_dora: true, round_type: 0)
    assert rule.valid?
  end

  test 'is invalid without round_type' do
    rule = Rule.new(aka_dora: true)
    assert rule.invalid?
  end

  test 'aka_dora default to true' do
    rule = Rule.new(round_type: 0)
    assert rule.aka_dora?
  end

  test 'aka_dora must be true or false' do
    rule = Rule.new(aka_dora: nil, round_type: 0)
    assert rule.invalid?

    rule = Rule.new(aka_dora: false, round_type: 0)
    assert rule.valid?
  end
end

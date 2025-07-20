# frozen_string_literal: true

require 'test_helper'

class AiTest < ActiveSupport::TestCase
  test 'is invalid without version' do
    ai = Ai.new(name: 'test')
    assert ai.invalid?
  end
end

# frozen_string_literal: true

require 'test_helper'

class FavoriteTest < ActiveSupport::TestCase
  test 'is valid with user and game' do
    user = users(:ryo)
    game = games(:tonnan)
    favorite = Favorite.new(user:, game:)
    assert favorite.valid?
  end

  test 'is invalid without user' do
    game = games(:tonnan)
    favorite = Favorite.new(game:)
    assert favorite.invalid?
  end

  test 'is invalid without game' do
    user = users(:ryo)
    favorite = Favorite.new(user:)
    assert favorite.invalid?
  end
end

# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'destroying user should also destroy players' do
    user = users(:ryo)
    assert_difference('Player.count', -user.players.count) do
      user.destroy
    end
  end

  test 'destroying user should also destroy favorites' do
    user = users(:ryo)
    assert_difference('Favorite.count', -user.favorites.count) do
      user.destroy
    end
  end

  test 'is invalid without name' do
    user = User.new(email: 'ryo@example.com')
    assert user.invalid?
  end

  test 'is invalid long name' do
    user = User.new(name: 'x' * 11)
    assert user.invalid?
  end
end

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
end

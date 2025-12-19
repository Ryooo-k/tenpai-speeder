# frozen_string_literal: true

require 'test_helper'

class FavoriteTest < ActiveSupport::TestCase
  test 'user must be oauth' do
    guest = users(:guest)
    guest_favorite = Favorite.new(user: guest, game: games(:tonnan))
    assert guest.provider.blank?
    assert guest_favorite.invalid?

    member = users(:ryo)
    member_favorite = Favorite.new(user: member, game: games(:tonnan))
    assert member.provider.present?
    assert member_favorite.valid?
  end
end

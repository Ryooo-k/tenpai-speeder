# frozen_string_literal: true

module GamesHelper
  def build_hand_position_class(player, user)
    if player.shimocha?(user)
      'absolute right-0 top-1/2 translate-x-1/2 -translate-y-1/2 origin-center -rotate-90'
    elsif player.toimen?(user)
      'absolute left-1/2 -translate-x-1/2 rotate-180'
    else
      'absolute left-0 top-1/2 -translate-x-1/2 -translate-y-1/2 origin-center rotate-90'
    end
  end

  def build_river_position_class(player, user)
    if player.shimocha?(user)
      'absolute top-1/2 right-1/20 -translate-x-1/2 -translate-y-1/2 -rotate-90'
    elsif player.toimen?(user)
      'absolute top-1/20 left-1/2 -translate-x-1/2 rotate-180'
    else
      'absolute top-1/2 right-1/2 -translate-x-1/2 -translate-y-1/2 rotate-90'
    end
  end
end

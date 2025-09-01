# frozen_string_literal: true

module GamesHelper
  def build_hand_position_class(player)
    case player.relation_from_user
    when :shimocha
      'right-0 top-1/2 translate-x-1/2 -translate-y-1/2 origin-center -rotate-90'
    when :toimen
      'left-1/2 -translate-x-1/2 rotate-180'
    when :kamicha
      'left-0 top-1/2 -translate-x-1/2 -translate-y-1/2 origin-center rotate-90'
    when :self
      'left-1/2 bottom-0 -translate-x-1/2'
    end
  end

  def build_river_position_class(player)
    case player.relation_from_user
    when :shimocha
      'top-1/2 right-1/20 -translate-x-1/2 -translate-y-1/2 -rotate-90'
    when :toimen
      'top-1/20 left-1/2 -translate-x-1/2 rotate-180'
    when :kamicha
      'top-1/2 right-1/2 -translate-x-1/2 -translate-y-1/2 rotate-90'
    end
  end

  def build_player_info_class(player)
    case player.relation_from_user
    when :shimocha
      'right-0 top-1/2 -translate-y-1/2 -rotate-90'
    when :toimen
      'left-1/2 -translate-x-1/2 rotate-180'
    when :kamicha
      'left-0 top-1/2 -translate-y-1/2 rotate-90'
    when :self
      'left-1/2 bottom-0 -translate-x-1/2'
    end
  end
end

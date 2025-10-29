# frozen_string_literal: true

module GamesHelper
  def build_hand_position_class(player)
    case player.relation_from_user
    when :shimocha
      'left-[100%] top-[84.7%] -rotate-90'
    when :toimen
      'left-[78.6%] translate-y-full rotate-180'
    when :kamicha
      'left-0 top-[15.3%] rotate-90'
    when :self
      'left-[21.4%] bottom-0'
    end
  end

  def build_river_position_class(player)
    case player.relation_from_user
    when :shimocha
      'top-[63.13%] left-2/3 -rotate-90'
    when :toimen
      'top-1/3 left-[59.85%] rotate-180'
    when :kamicha
      'top-[36.87%] left-1/3 rotate-90'
    when :self
      'top-2/3 left-[40.15%]'
    end
  end

  def build_melds_position_class(player)
    case player.relation_from_user
    when :shimocha
      'origin-bottom-right right-0 -translate-y-full -rotate-90'
    when :toimen
      'origin-bottom-right rotate-180 -translate-x-full -translate-y-full'
    when :kamicha
      'origin-bottom-right bottom-0 -translate-x-full rotate-90'
    when :self
      'origin-bottom-right bottom-0 right-0'
    end
  end

  def build_hand_partial_path(event, game, player)
    return 'games/mahjong_table/player/hand_plain' if game.current_player.ai? || player.ai?

    case event&.to_sym
    when :choose        then 'games/mahjong_table/player/hand_form'
    when :riichi_choose then 'games/mahjong_table/player/riichi_form'
    else                     'games/mahjong_table/player/hand_plain'
    end
  end

  def build_player_status_position_class(player)
    case player.relation_from_user
    when :shimocha
      'right-0 top-1/2 translate-x-1/2 -translate-y-1/2 origin-center -rotate-90'
    when :toimen
      'left-1/2 top-0 -translate-x-1/2 -translate-y-1/2 rotate-180'
    when :kamicha
      'left-0 top-1/2 -translate-x-1/2 -translate-y-1/2 origin-center rotate-90'
    when :self
      'left-1/2 bottom-0 -translate-x-1/2 translate-y-1/2'
    end
  end

  def discard_form_needed?(event, player)
    player.user? && event.in?([ 'choose', 'riichi_choose' ])
  end

  def build_hand_row_classes(player, needs_form)
    "flex#{(!needs_form && player.relation_from_user.in?([ :shimocha, :kamicha ]) ? ' -translate-y-[100%]' : '')}"
  end
end

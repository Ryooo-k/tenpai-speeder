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
    when :self
      'top-2/3 left-1/2 -translate-x-1/2'
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

  def build_hand_partial_path(event, game, player)
    return 'games/players/hand_plain' if game.current_player.ai? || player.ai?

    case event.to_sym
    when :choose        then 'games/players/hand_form'
    when :riichi_choose then 'games/players/riichi_form'
    else                     'games/players/hand_plain'
    end
  end

  def discard_form_needed?(event, player)
    player.user? && event.in?([ 'choose', 'riichi_choose' ])
  end

  def build_hand_row_classes(player, needs_form)
    "flex#{(!needs_form && player.relation_from_user.in?([ :shimocha, :kamicha ]) ? ' -translate-y-1/2' : '')}"
  end
end

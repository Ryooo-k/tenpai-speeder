# frozen_string_literal: true

module GamesHelper
  EVENT_PARTIALS = %w[
    draw
    confirm_tsumo
    confirm_kan
    switch_event_after_kan
    rinshan_draw
    tsumogiri
    confirm_riichi
    choose_riichi
    choose
    discard
    switch_event
    confirm_ron
    confirm_furo
    ryukyoku
    result
    game_end
  ].freeze

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
    when :choose_riichi then 'games/mahjong_table/player/riichi_form'
    when :choose_furo_safe_hand then 'games/mahjong_table/player/furo_safe_form'
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

  def build_result_position_class(player)
    case player.relation_from_user
    when :shimocha
      'right-0 top-1/2 -translate-y-1/2'
    when :toimen
      'left-1/2 -translate-x-1/2'
    when :kamicha
      'left-0 top-1/2 -translate-y-1/2'
    when :self
      'left-1/2 bottom-0 -translate-x-1/2'
    end
  end

  def discard_form_needed?(event, player)
    player.user? && event.in?([ 'choose', 'choose_riichi', 'choose_furo_safe_hand' ])
  end

  def build_hand_row_classes(player, needs_form)
    "flex#{(!needs_form && player.relation_from_user.in?([ :shimocha, :kamicha ]) ? ' -translate-y-[100%]' : '')}"
  end

  def event_partial_path(event)
    event_name = event.to_s
    return unless EVENT_PARTIALS.include?(event_name)

    "games/mahjong_table/events/#{event_name}"
  end

  def result_score_statement_for(player, score_statements)
    return if score_statements.blank?
    return unless score_statements.is_a?(Hash)

    statement = score_statements[player.id] || score_statements[player.id.to_s]

    if statement.nil?
      player_id_key = score_statements[:player_id] || score_statements['player_id']
      statement = score_statements if player_id_key == player.id
    end

    statement&.deep_symbolize_keys
  end
end

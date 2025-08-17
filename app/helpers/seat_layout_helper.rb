# frozen_string_literal: true

module SeatLayoutHelper
  def build_seat_placement_class(player, viewer)
    if player == viewer
      'bottom-0 left-1/2 -translate-x-1/2'
    elsif player.shimocha?(viewer)
      'right-0 top-1/2 translate-x-1/2 -translate-y-1/2 origin-center -rotate-90'
    elsif player.toimen?(viewer)
      'left-1/2 -translate-x-1/2 rotate-180'
    elsif player.kamicha?(viewer)
      'left-0 top-1/2 -translate-x-1/2 -translate-y-1/2 origin-center rotate-90'
    end
  end

  def build_hand_offset_class(player, viewer)
    '-translate-y-1/2' if player.shimocha?(viewer) || player.kamicha?(viewer)
  end
end

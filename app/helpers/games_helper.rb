# frozen_string_literal: true

module GamesHelper
  def determine_view_position(player, viewer)
    return :main     if player == viewer
    return :shimocha if player.shimocha?(viewer)
    return :toimen   if player.toimen?(viewer)
    :kamicha
  end
end

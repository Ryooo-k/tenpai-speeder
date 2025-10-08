# frozen_string_literal: true

class GamesController < ApplicationController
  def create
    game_mode_id = params.expect(:game_mode_id)
    game_mode = GameMode.find(game_mode_id)
    game = Game.new(game_mode:)
    ai = Ai.find_by!(version: '1.0')

    if game.save
      game.setup_players(current_user, ai)
      game.deal_initial_hands
      flash[:event] = :draw
      redirect_to game_play_path(game)
    else
      render :home
    end
  end
end

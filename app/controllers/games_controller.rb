# frozen_string_literal: true

class GamesController < ApplicationController
  def create
    game_mode_id = params.expect(:game_mode_id)
    game_mode = GameMode.find(game_mode_id)
    game = Game.new(game_mode:)
    ai = Ai.find_by!(version: '0.1')

    if game.save
      game_flow = GameFlow.new(game)
      payloads = game_flow.run({ event: 'game_start' }, current_user:, ai:)
      redirect_to game_play_path(game), flash: payloads
    else
      render :home
    end
  end
end

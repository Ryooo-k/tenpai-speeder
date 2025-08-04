# frozen_string_literal: true

class GamesController < ApplicationController
  def create
    game_mode_id = params.expect(:game_mode_id)
    game_mode = GameMode.find(game_mode_id)
    game = Game.new(game_mode:)
    ai_version = '1.0'

    # ユーザー認証は別途、実装する。
    current_user = User.find_by(name: :guest)
    ai = Ai.find_by(version: ai_version)

    if game.save
      game.setup_players(current_user, ai)
      game.deal_initial_hands
      redirect_to game_play_path(game)
    else
      render :home
    end
  end
end

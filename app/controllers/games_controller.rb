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
      redirect_to home_path, alert: 'ゲームの作成に失敗しました。時間をおいて再度お試しください。'
    end

  rescue GameFlow::SaveError => e
    Rails.logger.error("[GameFlow] SaveError while starting game: #{e.message} (#{e.cause&.class})")
    redirect_to home_path, alert: 'ゲームの保存に失敗しました。時間をおいて再度お試しください。'
  end
end

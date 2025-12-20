# frozen_string_literal: true

class Games::CommandsController < ApplicationController
  include Games::PlaySupport

  before_action :set_game

  def create
    game_flow = GameFlow.new(@game)
    payloads = game_flow.run(game_flow_params)

    respond_to do |format|
      format.turbo_stream { render_play_update(payloads) }
      format.html { redirect_to game_play_path(@game), flash: payloads }
    end

  rescue GameFlow::SaveError => e
    Rails.logger.error("[GameFlow] SaveError: #{e.message} (#{e.cause&.class})")
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = 'ゲームの保存に失敗しました。時間をおいて再度お試しください。'
        render 'games/plays/error'
      end
      format.html { redirect_to game_play_path(@game), alert: 'ゲームの保存に失敗しました。時間をおいて再度お試しください。' }
    end
  rescue GameFlow::UnknownEvent => e
    Rails.logger.warn("[GameFlow] UnknownEvent: #{e.message} (game_id=#{@game.id}, event=#{params[:event]})")
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = e.message
        render 'games/plays/error'
      end
      format.html { redirect_to game_play_path(@game), alert: e.message }
    end
  end
end

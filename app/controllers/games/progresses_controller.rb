# frozen_string_literal: true

class Games::ProgressesController < ApplicationController
  include Games::PlaySupport

  before_action :set_game

  def update
    @game.redo_with_sync! if @game.can_redo?

    payloads = { next_event: 'stop' }

    respond_to do |format|
      format.turbo_stream { render_play_update(payloads) }
      format.html { redirect_to game_play_path(@game), flash: payloads }
    end
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error("[GameFlow] ProgressError: #{e.message} (#{e.class})")
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = 'ゲームの復元に失敗しました。時間をおいて再度お試しください。'
        render 'games/plays/error'
      end
      format.html { redirect_to game_play_path(@game), alert: 'ゲームの復元に失敗しました。時間をおいて再度お試しください。' }
    end
  end
end

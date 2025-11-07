# frozen_string_literal: true

class FavoritesController < ApplicationController
  before_action :require_oauth_user!
  before_action :set_game, only: %i[ create destroy ]

  def create
    @favorite = current_user.favorites.find_or_create_by(game: @game)

    respond_to do |format|
      if @favorite.persisted?
        format.turbo_stream
        format.html { redirect_to game_play_path(@game) }
      else
        format.turbo_stream { head :unprocessable_entity }
        format.html { redirect_to game_play_path(@game) }
      end
    end
  end

  def destroy
    @favorite = current_user.favorites.find_by!(game: @game)

    respond_to do |format|
      if @favorite.destroy
        @favorite = nil
        format.turbo_stream
        format.html { redirect_to game_play_path(@game) }
      else
        format.turbo_stream { head :unprocessable_entity }
        format.html { redirect_to game_play_path(@game) }
      end
    end
  end

  private

    def set_game
      game_id = params.expect(:game_id)
      @game = Game.find(game_id)
    end
end

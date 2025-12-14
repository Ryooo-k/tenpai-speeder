# frozen_string_literal: true

class FavoritesController < ApplicationController
  before_action :require_oauth_user!
  before_action :set_game, only: %i[ create destroy ]
  before_action :load_favorites, only: :index

  def index
  end

  def create
    @favorite = current_user.favorites.create(game: @game)

    respond_to do |format|
      if @favorite.save
        format.turbo_stream
        format.html { redirect_back fallback_location: game_play_path(@game) }
      else
        Rails.logger.warn("[Favorite] Create failed for game_id=#{@game.id} user_id=#{current_user.id}")
        format.turbo_stream do
          flash.now[:alert] = 'お気に入り登録に失敗しました。時間をおいて再度お試しください。'
          render :error
        end
        format.html { redirect_back fallback_location: game_play_path(@game), alert: 'お気に入り登録に失敗しました。時間をおいて再度お試しください。' }
      end
    end
  end

  def destroy
    @favorite = current_user.favorites.find_by!(game: @game)
    load_favorites if refresh_favorites_list?

    respond_to do |format|
      if @favorite.destroy
        @favorite = nil
        format.turbo_stream
        format.html { redirect_back fallback_location: game_play_path(@game) }
      else
        Rails.logger.warn("[Favorite] Destroy failed for game_id=#{@game.id} user_id=#{current_user.id}")
        format.turbo_stream do
          flash.now[:alert] = 'お気に入り解除に失敗しました。時間をおいて再度お試しください。'
          render :error
        end
        format.html { redirect_back fallback_location: game_play_path(@game), alert: 'お気に入り解除に失敗しました。時間をおいて再度お試しください。' }
      end
    end
  end

  private

    def load_favorites
      @favorites = current_user.favorites.includes(game: :game_mode).order(created_at: :desc)
    end

    def set_game
      game_id = params.expect(:game_id)
      @game = Game.find(game_id)
    end

    def refresh_favorites_list?
      params[:context] == 'index'
    end
end

# frozen_string_literal: true

class Games::ActionsController < ApplicationController
  before_action :set_game
  before_action :action_params, only: :discard

  def draw
    @game.draw_for_current_player
    flash[:auto] = :choose if @game.current_player.ai?
    redirect_to game_play_path(@game)
  end

  # ai用打牌選択アクション
  def choose
    chosen_hand_id = @game.current_player.choose
    flash[:auto] = :discard
    flash[:chosen_hand_id] = chosen_hand_id
    redirect_to game_play_path(@game)
  end

  def discard
    chosen_hand_id = action_params.to_i
    @game.discard_for_current_player(chosen_hand_id)
    @game.advance_current_player!
    flash[:auto] = :draw
    redirect_to game_play_path(@game)
  end

  private

    def set_game
      @game = Game.includes(
        :game_mode,
        { players: [
          :user,
          :ai,
          { game_records: :honba },
          { player_states: [
            { hands: { tile: :base_tile } },
            { melds:  [ { tile: :base_tile }, :action ] },
            { rivers: { tile: :base_tile } },
          ] }
        ] },
        { rounds: [
          honbas: [
            { tile_orders: { tile: :base_tile } },
            { turns: :steps }
          ]
        ] }
      ).find(params[:game_id])
    end

    def action_params
      params.expect(:chosen_hand_id)
    end
end

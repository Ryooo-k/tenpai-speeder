# frozen_string_literal: true

class Games::PlaysController < ApplicationController
  before_action :set_game
  before_action :set_players, only: :show

  def show
    @auto_draw = play_params[:auto_draw]
    @auto_choose = play_params[:auto_choose]
    @auto_discard = play_params[:auto_discard]
    @chosen_hand_id = play_params[:chosen_hand_id]
  end

  private

    def set_game
      @game = Game.includes(
        :game_mode,
        { tiles: :base_tile },
        { players: [
          :user,
          :ai,
          { game_records: :honba }
        ] },
        { rounds: [
          honbas: [
            { tile_orders: { tile: :base_tile } },
            { turns: {
              steps: [
                { actions: :player },
                { player_states: [
                  { hands: { tile: :base_tile } },
                  { melds:  [ { tile: :base_tile }, :action ] },
                  { rivers: { tile: :base_tile } },
                  :player
                ] }
              ]
            } }
          ]
        ] }
      ).find(params[:game_id])
    end

    def set_players
      @user_player = @game.user_player
      @opponents = @game.opponents
    end

    def play_params
      params.permit(:auto_draw, :auto_choose, :auto_discard, :chosen_hand_id)
    end
end

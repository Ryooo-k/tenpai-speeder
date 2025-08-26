# frozen_string_literal: true

class Games::PlaysController < ApplicationController
  before_action :set_game
  before_action :set_players

  def show
    @auto = flash[:auto]&.to_sym
    @chosen_hand_id = flash[:chosen_hand_id]
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
end

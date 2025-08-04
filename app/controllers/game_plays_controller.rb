# frozen_string_literal: true

class GamePlaysController < ApplicationController
  def show
    @game = Game.includes(
      :game_mode,
      { tiles: :base_tile },
      { players: [
        :user,
        :ai,
        { scores: :honba }
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
    ).find(params[:id])
  end
end

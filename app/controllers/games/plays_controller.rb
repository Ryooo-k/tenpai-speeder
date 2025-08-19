# frozen_string_literal: true

class Games::PlaysController < ApplicationController
  def show
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

    @viewer = @game.players.user
  end
end

# frozen_string_literal: true

class Games::PlaysController < ApplicationController
  before_action :set_game
  before_action :set_players

  def show
    @action = flash[:next_action]&.to_sym
    @chosen_hand_id = flash[:chosen_hand_id]
    @discarded_tile_id = flash[:discarded_tile_id]

    if @action == :furo
      target_tile = @game.tiles.find(@discarded_tile_id)
      @furo_candidates = @game.user_player.find_furo_candidates(target_tile, @game.current_player)
    end
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
            { melds:  [ { tile: :base_tile } ] },
            { rivers: { tile: :base_tile } }
          ] }
        ] },
        { rounds: [
          honbas: [
            { tile_orders: { tile: :base_tile } },
            :steps
          ]
        ] }
      ).find(params[:game_id])
    end

    def set_players
      @user_player = @game.user_player
      @opponents = @game.opponents
    end
end

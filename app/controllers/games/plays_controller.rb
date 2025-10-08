# frozen_string_literal: true

class Games::PlaysController < ApplicationController
  before_action :set_game
  before_action :set_instance_variable, only: [ 'show' ]

  def show
  end

  def command
    game_flow = GameFlow.new(@game)
    payloads = game_flow.run(params)
    redirect_to game_play_path(@game), flash: payloads
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

    def set_instance_variable
      flash.each do |key, value|
        instance_variable_set("@#{key}", value)
      end

      if @event == 'riichi_choose'
        riichi_candidates = @game.current_player.find_riichi_candidates

        if @game.current_player.user?
          instance_variable_set(:@riichi_candidates, riichi_candidates)
        else
          chosen_hand_id = riichi_candidates.sample.id
          instance_variable_set(:@chosen_hand_id, chosen_hand_id)
        end
      end

      if @event == 'furo'
        discarded_tile = @game.tiles.find(@discarded_tile_id)
        furo_candidates = @game.user_player.find_furo_candidates(discarded_tile, @game.current_player)
        instance_variable_set(:@furo_candidates, furo_candidates)
      end
    end
end

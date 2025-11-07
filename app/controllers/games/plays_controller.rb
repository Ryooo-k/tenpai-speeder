# frozen_string_literal: true

class Games::PlaysController < ApplicationController
  before_action :set_game
  before_action :set_instance_variable, only: :show

  def show
  end

  def command
    game_flow = GameFlow.new(@game)
    payloads = game_flow.run(game_flow_params)
    redirect_to game_play_path(@game), flash: payloads

  rescue GameFlow::UnknownEvent => e
    redirect_to home_path, alert: e.message
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

      @shanten = @game.user_player.shanten
      @outs = @game.user_player.outs[:normal]
      @outs_kind = @outs.map(&:code).tally.keys.count
      @favorite = current_user&.favorites&.find_by(game: @game)
    end

    def game_flow_params
      event = params.expect(:event)
      flow_requests = { event: }

      case event.to_sym
      when :discard
        chosen_hand_id = params.expect(:chosen_hand_id)
        flow_requests[:chosen_hand_id] = chosen_hand_id.to_i
      when :furo
        discarded_tile_id, furo_type, furo_ids = params.expect(:discarded_tile_id, :furo_type, furo_ids: [])
        flow_requests[:discarded_tile_id] = discarded_tile_id.to_i
        flow_requests[:furo_type] = furo_type.to_s
        flow_requests[:furo_ids] = furo_ids.map(&:to_i)
      when :ron
        discarded_tile_id, ron_player_ids = params.expect(:discarded_tile_id, ron_player_ids: [])
        flow_requests[:discarded_tile_id] = discarded_tile_id.to_i
        flow_requests[:ron_player_ids] = ron_player_ids.map(&:to_i)
      end

      flow_requests
    end
end

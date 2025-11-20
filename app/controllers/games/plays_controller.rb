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

  def undo
    if @game.can_undo?
      @game.undo_step
      @game.sync_current_seat
      @game.sync_draw_count
      @game.sync_kan_count
      @game.sync_riichi_count
    end

    redirect_to game_play_path(@game), flash: { next_event: 'stop' }
  end

  def redo
    if @game.can_redo?
      @game.redo_step
      @game.sync_current_seat
      @game.sync_draw_count
      @game.sync_kan_count
      @game.sync_riichi_count
    end

    redirect_to game_play_path(@game), flash: { next_event: 'stop' }
  end

  def playback
    @game.destroy_future_steps
    redirect_to game_play_path(@game), flash: { next_event: @game.current_step.next_event }
  end

  private

    def set_game
      @game = Game.includes(
        :game_mode,
        { tiles: :base_tile },
        { players: [
          :user, :ai,
          { game_records: :honba },
          { player_states: [
            { step: :honba },
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
        name = key == 'next_event' ? 'event' : key
        instance_variable_set("@#{name}", value)
      end

      if @event == 'confirm_furo'
        discarded_tile = @game.tiles.find(@discarded_tile_id)
        @furo_candidates = @game.user_player.find_furo_candidates(discarded_tile, @game.current_player)
      end

      @shanten = @game.user_player.shanten
      @outs = @game.user_player.outs[:normal]
      @outs_kind = @outs.map(&:code).tally.keys.count
      @favorite = current_user&.favorites&.find_by(game: @game)
      @can_undo = @game.can_undo?
      @can_redo = @game.can_redo?
      @can_playback = @event == 'stop' || @event.blank?
    end

    def game_flow_params
      event = params.expect(:event)
      flow_requests = { event: }

      case event.to_sym
      when :confirm_tsumo
        tsumo = params.expect(:tsumo)
        flow_requests[:tsumo] = ActiveModel::Type::Boolean.new.cast(tsumo)
      when :confirm_riichi
        riichi = params.expect(:riichi)
        flow_requests[:riichi] = ActiveModel::Type::Boolean.new.cast(riichi)
      when :choose_riichi
        riichi_candidate_ids = params.expect(riichi_candidate_ids: [])
        flow_requests[:riichi_candidate_ids] = riichi_candidate_ids.map(&:to_i)
      when :discard
        chosen_hand_id = params.expect(:chosen_hand_id)
        flow_requests[:chosen_hand_id] = chosen_hand_id.to_i
      when :confirm_ron
        discarded_tile_id, ron_player_ids = params.expect(:discarded_tile_id, ron_player_ids: [])
        flow_requests[:discarded_tile_id] = discarded_tile_id
        flow_requests[:ron_player_ids] = ron_player_ids.reject(&:blank?).map(&:to_i)
      when :confirm_furo
        furo = params.expect(:furo)
        flow_requests[:furo] = ActiveModel::Type::Boolean.new.cast(furo)

        if flow_requests[:furo]
          discarded_tile_id, furo_type, furo_ids = params.expect(:discarded_tile_id, :furo_type, furo_ids: [])
          flow_requests[:discarded_tile_id] = discarded_tile_id.to_i
          flow_requests[:furo_type] = furo_type.to_s
          flow_requests[:furo_ids] = furo_ids.map(&:to_i)
        end
      when :result
        ryukyoku = params.expect(:ryukyoku)
        flow_requests[:ryukyoku] = ActiveModel::Type::Boolean.new.cast(ryukyoku)
      end

      flow_requests
    end
end

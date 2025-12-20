# frozen_string_literal: true

module Games::PlaySupport
  extend ActiveSupport::Concern

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

    def set_instance_variable(payloads = nil)
      data = payloads || flash.to_hash

      data.each do |key, value|
        name = key.to_s == 'next_event' ? 'event' : key
        instance_variable_set("@#{name}", value)
      end

      @favorite = current_user&.favorites&.find_by(game: @game)
      @can_playback = @event == 'stop' || @event.blank?
    end

    def render_play_update(payloads)
      set_instance_variable(payloads)
      render 'games/plays/update'
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
        discarded_tile_id, kakan, ron_player_ids = params.expect(:discarded_tile_id, :kakan, ron_player_ids: [])
        flow_requests[:discarded_tile_id] = discarded_tile_id
        flow_requests[:kakan] = ActiveModel::Type::Boolean.new.cast(kakan)
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
      when :confirm_kan
        kan = params.expect(:kan)
        flow_requests[:kan] = ActiveModel::Type::Boolean.new.cast(kan)

        if flow_requests[:kan]
          kan_type, kan_ids = params.expect(:kan_type, kan_ids: [])
          flow_requests[:kan_type] = kan_type.to_s
          flow_requests[:kan_ids] = kan_ids.map(&:to_i)
        end
      when :result
        ryukyoku = params.expect(:ryukyoku)
        flow_requests[:ryukyoku] = ActiveModel::Type::Boolean.new.cast(ryukyoku)
      end

      flow_requests
    end
end

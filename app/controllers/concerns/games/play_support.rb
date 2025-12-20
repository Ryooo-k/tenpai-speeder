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
end

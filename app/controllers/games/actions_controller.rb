# frozen_string_literal: true

class Games::ActionsController < ApplicationController
  before_action :set_game
  before_action :action_params, only: :discard

  def draw
    @game.draw_for_current_player
    auto_choose = true if @game.current_player.ai?
    redirect_to game_play_path(@game, auto_choose:)
  end

  # ai用打牌選択アクション
  def choose
    chosen_hand_id = @game.current_player.choose
    redirect_to game_play_path(@game, auto_discard: true, chosen_hand_id:)
  end

  def discard
    @game.discard_for_current_player(action_params.to_i)
    @game.advance_current_player!
    auto_draw = true
    redirect_to game_play_path(@game, auto_draw:)
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

    def action_params
      params.expect(:chosen_hand_id)
    end
end

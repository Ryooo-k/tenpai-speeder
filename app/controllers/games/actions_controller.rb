# frozen_string_literal: true

class Games::ActionsController < ApplicationController
  before_action :set_game

  def draw
    current_player.draw
    auto_draw = false
    auto_choose = true if current_player.ai?
    redirect_to game_play_path(@game, auto_draw:, auto_choose:)
  end

  # ai用打牌選択アクション
  def choose
    chosen_tile_id = current_player.choose
    auto_draw = false
    auto_discard = true
    redirect_to game_play_path(@game, auto_draw:, auto_discard:, chosen_tile_id:)
  end

  def discard
    current_player.discard(action_params[:selected_tile_id])
    auto_draw = true
    @game.advance
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

    def current_player
      @game.current_player
    end

    def action_params
      params.expect(:selected_tile_id)
    end
end

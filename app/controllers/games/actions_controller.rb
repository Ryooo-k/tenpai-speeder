# frozen_string_literal: true

class Games::ActionsController < ApplicationController
  before_action :set_game

  def draw
    @game.draw_for_current_player

    if @game.current_player.can_tsumo?
      flash[:next_action] = :tsumo
    elsif @game.current_player.riichi?
      flash[:next_action] = :discard
      flash[:chosen_hand_id] = @game.current_player.hands.last.id
    elsif @game.current_player.can_riichi?
      flash[:next_action] = :confirm_riichi
    else
      flash[:next_action] = :choose
    end

    redirect_to game_play_path(@game)
  end

  def choose
    chosen_hand_id = @game.current_player.choose
    flash[:next_action] = :discard
    flash[:chosen_hand_id] = chosen_hand_id
    redirect_to game_play_path(@game)
  end

  def discard
    chosen_hand_id = params.expect(:chosen_hand_id).to_i
    discarded_tile = @game.discard_for_current_player(chosen_hand_id)

    ron_claimers = @game.find_ron_claimers(discarded_tile)
    if ron_claimers.present?
      flash[:next_action] = :confirm_ron
      flash[:discarded_tile_id] = discarded_tile.id
      flash[:ron_claimer_ids] = ron_claimers.map(&:id)
    else
      # 現状aiは副露を学習していないため、
      # userが打牌した際のai_player副露はせずdrawアクションに移行する。
      # aiが副露を学習後、ai用副露処理の実装を行う。
      is_user_furo = @game.user_player.can_furo?(discarded_tile, @game.current_player)
      if is_user_furo
        flash[:next_action] = :confirm_furo
        flash[:discarded_tile_id] = discarded_tile.id
      else
        @game.advance_current_player!
        flash[:next_action] = :draw
      end
    end

    redirect_to game_play_path(@game)
  end

  def ron
    discarded_tile_id = params.expect(:discarded_tile_id).to_i
    ron_claimer_ids = params.expect(ron_claimer_ids: []).map(&:to_i)

    score_statements = @game.build_ron_score_statements(discarded_tile_id, ron_claimer_ids)
    @game.give_ron_point(score_statements)
    @game.give_bonus_point(ron_claimer_ids:)

    if ron_claimer_ids.include?(@game.host_player.id)
      @game.advance_next_honba!
    else
      @game.advance_next_round!
    end

    @game.deal_initial_hands
    flash[:next_action] = :draw
    redirect_to game_play_path(@game)
  end

  def furo
    furo_type = params.expect(:furo_type)
    furo_ids = params.expect(furo_ids: []).map(&:to_i)
    discarded_tile_id = params.expect(:discarded_tile_id).to_i

    @game.apply_furo(furo_type, furo_ids, discarded_tile_id)
    @game.advance_to_player!(@game.user_player)
    flash[:next_action] = :choose
    redirect_to game_play_path(@game)
  end

  def tsumo
    @game.give_tsumo_point
    @game.give_bonus_point

    if @game.current_player.host?
      @game.advance_next_honba!
    else
      @game.advance_next_round!
    end

    @game.deal_initial_hands
    flash[:next_action] = :draw
    redirect_to game_play_path(@game)
  end

  def riichi
    @game.current_player.current_state.update!(riichi: true)
    flash[:next_action] = :choose
    redirect_to game_play_path(@game)
  end

  def through
    @game.advance_current_player!
    flash[:next_action] = :draw
    redirect_to game_play_path(@game)
  end

  def pass
    flash[:next_action] = :choose
    redirect_to game_play_path(@game)
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
end

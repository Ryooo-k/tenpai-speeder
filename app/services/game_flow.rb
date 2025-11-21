# frozen_string_literal: true

class GameFlow
  class UnknownEvent < StandardError; end

  def initialize(game)
    @game = game
    @payloads = {}
  end

  def run(params, current_user: nil, ai: nil)
    event = params[:event].to_sym

    case event
    when :game_start     then game_start(current_user, ai)
    when :draw           then draw
    when :confirm_tsumo  then confirm_tsumo(params)
    when :tsumogiri      then tsumogiri
    when :confirm_riichi then confirm_riichi(params)
    when :choose_riichi  then choose_riichi(params)
    when :choose         then choose
    when :discard        then discard(params)
    when :switch_event   then switch_event
    when :confirm_ron    then confirm_ron(params)
    when :confirm_furo   then confirm_furo(params)
    when :ryukyoku       then ryukyoku
    when :result         then result(params)
    when :stop           then return @payloads
    else
      raise UnknownEvent, "不明なイベント名です：#{event}"
    end

    @payloads
  end

  private

    def game_start(current_user, ai)
      @game.setup_players(current_user, ai)
      @game.apply_game_mode
      @game.deal_initial_hands

      next_event = 'draw'
      @game.current_step.update!(next_event:, draw_count: @game.latest_honba.draw_count)
      @payloads[:next_event] = next_event
    end

    def draw
      @game.draw_for_current_player

      if @game.current_player.can_tsumo?
        next_event = 'confirm_tsumo'
      elsif @game.current_player.riichi?
        next_event = 'tsumogiri'
      elsif @game.current_player.can_riichi?
        next_event = 'confirm_riichi'
      else
        next_event = 'choose'
      end

      @game.current_step.update!(next_event:)
      @payloads[:next_event] = next_event
    end

    def confirm_tsumo(params)
      if params[:tsumo]
        winner = @game.current_player
        score_statements = winner.score_statements
        @game.give_tsumo_point
        @game.give_bonus_point

        @payloads[:score_statements] = { winner.id => score_statements }
        @payloads[:ryukyoku] = false
        next_event = 'result'
      else
        next_event = 'choose'
      end

      @payloads[:next_event] = next_event
    end

    def tsumogiri
      drawn_hand = @game.current_player.hands.detect(&:drawn)
      @payloads[:chosen_hand_id] = drawn_hand.id
      @payloads[:next_event] = 'discard'
    end

    def confirm_riichi(params)
      if params[:riichi]
        @game.current_player.current_state.update!(riichi: true)
        riichi_candidates = @game.current_player.find_riichi_candidates
        @payloads[:riichi_candidate_ids] = riichi_candidates.map(&:id)
        next_event = 'choose_riichi'
      else
        next_event = 'choose'
      end

      @payloads[:next_event] = next_event
    end

    def choose_riichi(params)
      @payloads[:chosen_hand_id] = params[:riichi_candidate_ids].sample
      @payloads[:next_event] = 'discard'
    end

    def choose
      chosen_hand = @game.current_player.choose
      @payloads[:chosen_hand_id] = chosen_hand.id
      @payloads[:next_event] = 'discard'
    end

    def discard(params)
      chosen_hand_id = params[:chosen_hand_id]
      @game.discard_for_current_player(chosen_hand_id)
      next_event = 'switch_event'
      @game.current_step.update!(next_event:)
      @payloads[:next_event] = next_event
    end

    def switch_event
      discarded_tile = @game.current_player.rivers.last.tile
      ron_eligible_players = @game.find_ron_players(discarded_tile)
      is_user_furo = @game.user_player.can_furo?(discarded_tile, @game.current_player)

      if ron_eligible_players.present?
        @payloads[:ron_eligible_players_ids] = ron_eligible_players.map(&:id)
        @payloads[:discarded_tile_id] = discarded_tile.id
        next_event = 'confirm_ron'
      elsif @game.live_wall_empty?
        next_event = 'ryukyoku'
      elsif is_user_furo
        @payloads[:discarded_tile_id] = discarded_tile.id
        next_event = 'confirm_furo'
      else
        @game.advance_current_player!
        next_event = 'draw'
      end

      @payloads[:non_refresh_kyoku_status] = true
      @payloads[:next_event] = next_event
    end

    def confirm_ron(params)
      ron_player_ids = params[:ron_player_ids]

      if ron_player_ids.present?
        score_statements = @game.build_ron_score_statements(params[:discarded_tile_id], ron_player_ids)
        @game.give_ron_point(score_statements)
        @game.give_bonus_point(ron_player_ids:)

        @payloads[:score_statements] = score_statements
        @payloads[:ryukyoku] = false
        next_event = 'result'
      else
        @game.advance_current_player!
        next_event = 'draw'
      end

      @payloads[:next_event] = next_event
    end

    def confirm_furo(params)
      if params[:furo]
        @game.apply_furo(params[:furo_type], params[:furo_ids], params[:discarded_tile_id])
        @game.advance_to_player!(@game.user_player)
        next_event = 'choose'
        @game.current_step.update!(next_event:)
      else
        @game.advance_current_player!
        next_event = 'draw'
      end

      @payloads[:next_event] = next_event
    end

    def ryukyoku
      @game.give_tenpai_point
      @payloads[:ryukyoku] = true
      @payloads[:next_event] = :result
    end

    def result(params)
      renchan = @game.host_winner?
      ryukyoku = params[:ryukyoku]

      if renchan
        @game.advance_next_honba!(ryukyoku:)
        @game.deal_initial_hands
        next_event = 'draw'
      elsif !renchan && @game.game_end?
        next_event = 'game_end'
      else
        @game.advance_next_round!(ryukyoku:)
        @game.deal_initial_hands
        next_event = 'draw'
      end

      @payloads[:refresh_header] = true
      @payloads[:next_event] = next_event
    end
end

# frozen_string_literal: true

class GameFlow
  def initialize(game)
    @game = game
    @payloads = {}
  end

  def run(params)
    event = params[:event].to_sym

    case event
    when :draw     then draw
    when :choose   then choose
    when :discard  then discard(params)
    when :riichi   then riichi
    when :furo     then furo(params)
    when :ron      then ron(params)
    when :tsumo    then tsumo
    when :through  then through
    when :pass     then pass
    when :ryukyoku then ryukyoku
    when :agari    then agari
    else
      raise ArgumentError, "Unknown event: #{event.inspect}"
    end

    @payloads
  end

  private

    def draw
      if @game.live_wall_empty?
        @game.give_tenpai_point
        @payloads[:event] = :kyoku_result
        return
      end

      @game.draw_for_current_player

      if @game.current_player.can_tsumo?
        @payloads[:event] = :confirm_tsumo
      elsif @game.current_player.riichi?
        @payloads[:chosen_hand_id] = @game.current_player.hands.find_by(drawn: true).id
        @payloads[:event] = :discard
      elsif @game.current_player.can_riichi?
        @payloads[:event] = :confirm_riichi
      else
        @payloads[:event] = :choose
      end
    end

    def choose
      chosen_hand_id = @game.current_player.choose
      @payloads[:chosen_hand_id] = chosen_hand_id
      @payloads[:event] = :discard
    end

    def discard(params)
      chosen_hand_id = params[:chosen_hand_id].to_i
      discarded_tile = @game.discard_for_current_player(chosen_hand_id)

      ron_players = @game.find_ron_players(discarded_tile)
      if ron_players.present?
        @payloads[:discarded_tile_id] = discarded_tile.id
        @payloads[:ron_player_ids] = ron_players.map(&:id)
        @payloads[:event] = :confirm_ron
        return
      end

      # 現状aiは副露を学習していないため、userが打牌した際、aiの副露はせずdrawアクションに移行する。
      is_user_furo = @game.user_player.can_furo?(discarded_tile, @game.current_player)
      if is_user_furo
        @payloads[:discarded_tile_id] = discarded_tile.id
        @payloads[:event] = :confirm_furo
      else
        @game.advance_current_player!
        @payloads[:event] = :draw
      end
    end

    def furo(params)
      furo_type = params[:furo_type]
      furo_ids = params[:furo_ids].map(&:to_i)
      discarded_tile_id = params[:discarded_tile_id].to_i
      @game.apply_furo(furo_type, furo_ids, discarded_tile_id)
      @game.advance_to_player!(@game.user_player)
      @payloads[:event] = :choose
    end

    def riichi
      @game.current_player.current_state.update!(riichi: true)
      @payloads[:event] = :riichi_choose
    end

    def ron(params)
      discarded_tile_id = params[:discarded_tile_id].to_i
      ron_player_ids = params[:ron_player_ids].map(&:to_i)
      score_statements = @game.build_ron_score_statements(discarded_tile_id, ron_player_ids)
      @game.give_ron_point(score_statements)
      @game.give_bonus_point(ron_player_ids:)
      @payloads[:discarded_tile_id] = discarded_tile_id
      @payloads[:score_statements] = score_statements
      @payloads[:event] = :kyoku_result
    end

    def tsumo
      @game.give_tsumo_point
      @game.give_bonus_point
      @payloads[:event] = :kyoku_result
    end

    def through
      @game.advance_current_player!
      @payloads[:event] = :draw
    end

    def pass
      @payloads[:event] = :choose
    end

    def ryukyoku
      if @game.host.tenpai?
        @game.advance_next_honba!(ryukyoku: true)
      else
        @game.advance_next_round!(ryukyoku: true)
      end

      @game.deal_initial_hands
      @payloads[:event] = :draw
    end

    def agari
      if @game.host_winner?
        @game.advance_next_honba!
      else
        @game.advance_next_round!
      end

      @game.deal_initial_hands
      @payloads[:event] = :draw
    end
end

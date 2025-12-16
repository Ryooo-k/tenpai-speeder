# frozen_string_literal: true

class SituationalYakuListBuilder
  def initialize(player)
    @player = player
  end

  def build(tile: nil, kakan: false)
    {
      riichi:        player.riichi?,
      double_riichi: double_riichi?,
      ippatsu:       ippatsu?,
      tenhou:        tenhou?,
      chiihou:       chiihou?,
      haitei:        haitei_tsumo?,
      houtei:        houtei_ron?(tile),
      rinshan:       rinshan_tsumo?,
      chankan:       chankan?(tile, kakan)
    }
  end

  private

    attr_reader :player

    delegate :hands, :melds, :rivers, :game, :current_state, to: :player

    def double_riichi?
      riichi_state = base_states.detect(&:riichi)
      return false unless riichi_state

      is_first_turn = riichi_state.rivers.size == 1
      is_nobody_furo = PlayerState.for_honba(game.latest_honba).up_to_step(riichi_state.step.number).with_melds.empty?
      is_first_turn && is_nobody_furo
    end

    def ippatsu?
      riichi_state = base_states.detect(&:riichi)
      return false if riichi_state.blank? || rivers.blank? || !rivers.any?(&:riichi) || !rivers.last.riichi?

      range_after_riichi = riichi_state.step.number..current_state.step.number
      states_after_riichi = PlayerState.for_honba(game.latest_honba).in_step_range(range_after_riichi)
      states_after_riichi.with_melds.empty?
    end

    def tenhou?
      complete? && nobody_discard? && nobody_furo?
    end

    def chiihou?
      complete? && player.rivers.empty? && nobody_furo?
    end

    def haitei_tsumo?
      game.remaining_tile_count.zero? && complete?
    end

    def houtei_ron?(tile)
      return false unless tile

      test_hands = hands + [ tile ]
      shanten = HandEvaluator.calculate_shanten(test_hands, melds)
      game.remaining_tile_count.zero? && shanten.negative?
    end

    def rinshan_tsumo?
      return false unless complete?
      hands.any? { |hand| hand.drawn && hand.rinshan }
    end

    def chankan?(tile, kakan)
      return false unless tile

      test_hands = hands + [ tile ]
      shanten = HandEvaluator.calculate_shanten(test_hands, melds)

      if tile.is_a?(Meld)
        tile.kind == 'kakan' && shanten.negative?
      else
        kakan && shanten.negative?
      end
    end

    def nobody_furo?
      game.players.all? { |player| player.melds.empty? }
    end

    def nobody_discard?
      game.players.all? { |player| player.rivers.empty? }
    end

    def complete?
      player.shanten.negative?
    end

    def base_states
      player.send(:base_states)
    end

    def base_rivers
      player.send(:base_rivers)
    end
end

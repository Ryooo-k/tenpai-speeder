# frozen_string_literal: true

module StateEncoder
  class UnsupportedAi < StandardError; end

  NORMALIZATION_BASE_OUTS = 10.0
  NORMALIZATION_DRAW_COUNT = 122.0
  PLACEHOLDER_VALUE = -1.0
  TILE_KIND_COUNT   = 34.0
  MAX_CALL_COUNT    = 4
  MAX_MELD_COUNT    = 16
  MAX_RIVER_COUNT   = 24
  MAX_DORA_COUNT    = 5

  class << self
    def call(game, player)
      case player.ai_version
      when 'v1.0' then build_v1_states(game, player)
      else
        raise UnsupportedAi, "AIバージョンが未対応です"
      end
    end

    private

      def build_v1_states(game, main_player)
        main_player_states = [
                                main_player.tenpai? ? 1.0 : 0.0,
                                encode_hands(main_player.hands),
                                encode_melds(main_player.melds),
                                encode_rivers(main_player.rivers),
                                main_player.shanten,
                                main_player.outs.map { |_, v| v.count }.min / NORMALIZATION_BASE_OUTS
                              ].flatten

        other_player_states = game.players.map do |player|
                                next if main_player == player
                                [
                                  player.riichi? ? 1.0 : 0.0,
                                  encode_melds(player.melds),
                                  encode_rivers(player.rivers)
                                ]
                              end.compact.flatten

        game_states = [
                        game.remaining_tile_count / NORMALIZATION_DRAW_COUNT,
                        encode_dora_indicators(game.dora_indicator_tiles)
                      ].flatten

        states = main_player_states + other_player_states + game_states
        Torch.tensor(states, dtype: :float32)
      end

      def encode_hands(hands)
        counter = Array.new(TILE_KIND_COUNT, 0)
        hands.each { |hand| counter[hand.code] += 1 }
        counter
      end

      def encode_melds(melds)
        encoded_melds = Array.new(MAX_MELD_COUNT, PLACEHOLDER_VALUE)
        melds.each_with_index do |tile, order|
          encoded_melds[order] = tile.code / TILE_KIND_COUNT
        end
        encoded_melds.flatten
      end

      def encode_rivers(rivers)
        encoded_rivers= Array.new(MAX_RIVER_COUNT, PLACEHOLDER_VALUE)
        rivers.each_with_index do |river, order|
          encoded_rivers[order] = river.code / TILE_KIND_COUNT
        end
        encoded_rivers
      end

      def encode_dora_indicators(indicators)
        encoded_indicators = Array.new(MAX_DORA_COUNT, PLACEHOLDER_VALUE)
        indicators.each_with_index do |tile, order|
          next if tile.nil?
          encoded_indicators[order] = tile.code / TILE_KIND_COUNT
        end
        encoded_indicators
      end
    end
end

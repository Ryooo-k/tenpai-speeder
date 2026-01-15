# frozen_string_literal: true

module MahjongAi
  class UnsupportedAi < StandardError; end

  class << self
    def infer(game, player)
      raise UnsupportedAi, 'AIバージョンが未対応です' if unsupported_ai_version?(player)

      q_net = QNetLoader.fetch(player)
      states = StateEncoder.call(game, player)
      output = q_net.call(states)
      output.argmax.item
    end

    private

      def unsupported_ai_version?(player)
        return true if player.user?
        !AI_CONFIGS.keys.include?(player.ai_version)
      end
  end
end

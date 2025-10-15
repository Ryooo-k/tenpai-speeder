# frozen_string_literal: true

module MahjongAi
  class UnsupportedAi < StandardError; end

  class << self
    def infer(game, player)
      raise UnsupportedAi, 'AIバージョンが未対応です' unless supported_ai_version?(player)

      config = AI_CONFIGS[player.ai_version]
      q_net = QNet.new(config['input_size'], config['hidden_layers'], config['output_size'])
      q_net.load_state_dict(Torch.load(config['path']))
      q_net.eval

      states = StateEncoder.call(game, player)
      output = q_net.call(states)
      output.argmax.item
    end

    private

      def supported_ai_version?(player)
        return false if player.user?
        AI_CONFIGS.keys.include?(player.ai_version)
      end
  end
end

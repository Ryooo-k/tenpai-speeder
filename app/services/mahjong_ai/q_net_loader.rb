# frozen_string_literal: true

module MahjongAi
  class QNetLoader
    @models = {}
    @mutex = Mutex.new

    class << self
      def fetch(player)
        config = AI_CONFIGS.fetch(player.ai_version)
        key = config['path']

        @models[key] || @mutex.synchronize do
          @models[key] ||= build_and_load(config)
        end
      end

      private

        def build_and_load(config)
          Torch.no_grad do
            q_net = build_q_net(config)
            state = Torch.load(config['path'])
            q_net.load_state_dict(state)
            q_net.eval.freeze
            q_net
          end
        end

      def build_q_net(config)
        QNet.new(config['input_size'], config['hidden_layers'], config['output_size'])
      end
    end
  end
end

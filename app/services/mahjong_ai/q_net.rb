# frozen_string_literal: true

module MahjongAi
  class QNet < Torch::NN::Module
    def initialize(input_size, hidden_layers, output_size)
      super()
      layers = build_layers(input_size, hidden_layers, output_size)
      @network = Torch::NN::Sequential.new(*layers)
    end

    def forward(states)
      @network.call(states)
    end

    private

      def build_layers(input_size, hidden_layers, output_size)
        layers = []
        last = input_size

        hidden_layers.each do |hidden|
          layers << Torch::NN::Linear.new(last, hidden)
          layers << Torch::NN::ReLU.new
          last = hidden
        end
        layers << Torch::NN::Linear.new(last, output_size)
        layers
      end
  end
end

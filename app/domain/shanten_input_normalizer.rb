# frozen_string_literal: true

module ShantenInputNormalizer
  TILE_KIND_COUNT = 34

  class << self
    def normalize(hands, melds)
      code_map = Array.new(TILE_KIND_COUNT, 0)
      hands.each { |hand| code_map[hand.code] += 1 }
      melds.each do |meld|
        code = meld.code

        case meld.kind.to_sym
        when :chi
          code_map[code] += 1
        when :pon
          code_map[code] += 1
        else
          next if meld.from.present?
          code_map[code] += 1
        end
      end

      manzu_code  = code_map[0..8].to_s
      pinzu_code  = code_map[9..17].to_s
      souzu_code  = code_map[18..26].to_s
      zihai_code  = code_map[27..33].to_s
      [ manzu_code, pinzu_code, souzu_code, zihai_code  ]
    end
  end
end

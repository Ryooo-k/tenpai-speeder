# frozen_string_literal: true

module ScoreInputNormalizer
  RELATION_MARK = {
    self: '_',
    shimocha: '-',
    toimen: '=',
    kamicha: '+'
  }

  class << self
    def normalize(hands, melds, target, relation)
      normalized_hands = normalize_hands(hands)
      normalized_melds = normalize_melds(melds)
      normalized_target = normalize_target(target, relation)
      [ normalized_hands, normalized_melds, normalized_target ]
    end

    def normalize_hands(hands)
      normalized_hands = {
        m: Array.new(9, 0),
        p: Array.new(9, 0),
        s: Array.new(9, 0),
        z: Array.new(7, 0)
      }

      hands.each do |hand|
        suit = hand.suit.first.to_sym
        number_index = hand.number - 1
        normalized_hands[suit][number_index] += 1
      end
      normalized_hands
    end

    def normalize_melds(melds)
      pon_and_kakan = normalize_pon_and_kakan_melds(melds)
      chi = normalize_chi_melds(melds)
      daiminkan = normalize_daiminkan_melds(melds)
      ankan = normalize_ankan_melds(melds)
      [ pon_and_kakan, chi, daiminkan, ankan ].flatten
    end

    def normalize_target(target, relation)
      suit = target.suit.first
      number = target.number

      case relation
      when :self
        "#{suit}#{number}_"
      when :shimocha
        "#{suit}#{number}-"
      when :toimen
        "#{suit}#{number}="
      when :kamicha
        "#{suit}#{number}+"
      end
    end

    private

      def normalize_pon_and_kakan_melds(melds)
        pon_melds = melds.select { |meld| meld.kind == 'pon' }
        kakan_melds = melds.select { |meld| meld.kind == 'kakan' }

        normalized_pon_melds = pon_melds.map do |meld|
          next unless meld.from.present?
          suit = meld.tile.suit.first
          number = meld.tile.number
          relation = RELATION_MARK.fetch(meld.from.to_sym)
          "#{suit}#{number}#{number}#{number}#{relation}"
        end.compact

        kakan_melds.present? ? normalize_kakan_melds(kakan_melds, normalized_pon_melds) : normalized_pon_melds
      end

      def normalize_kakan_melds(kakan_melds, normalized_pon_melds)
        normalized_melds = []
        kakan_melds.each do |kakan_meld|
          suit = kakan_meld.tile.suit.first
          number = kakan_meld.tile.number

          normalized_pon_melds.each do |pon_meld|
            if pon_meld.include?("#{suit}#{number}")
              tail = pon_meld.last
              normalized_melds << "#{suit}#{number}#{number}#{number}#{number}#{tail}"
            else
              normalized_melds << pon_meld
            end
          end
        end
        normalized_melds
      end

      def normalize_chi_melds(melds)
        chi_melds = melds.select { |meld| meld.kind == 'chi' }

        chi_groups = chi_melds.map do |meld|
              suit = meld.tile.suit.first
              number = meld.tile.number
              relation = meld.from.present? ? RELATION_MARK.fetch(meld.from.to_sym) : nil
              { suit:, number:, relation: }
            end.each_slice(3).to_a

        chi_groups.map do |chi_groupe|
          suit = chi_groupe.first[:suit]
          numbers = chi_groupe.sort_by { |chi| chi[:number] }.map do |chi|
                      chi[:relation].present? ? "#{chi[:number]}#{chi[:relation]}" : chi[:number].to_s
                    end
          numbers.unshift(suit).join
        end
      end

      def normalize_daiminkan_melds(melds)
        daiminkan_melds = melds.select { |meld| meld.kind == 'daiminkan' }

        daiminkan_melds.map do |meld|
          next unless meld.from.present?
          suit = meld.tile.suit.first
          number = meld.tile.number
          relation = RELATION_MARK.fetch(meld.from.to_sym)
          "#{suit}#{number}#{number}#{number}#{number}#{relation}"
        end.compact
      end

      def normalize_ankan_melds(melds)
        ankan_melds = melds.select { |meld| meld.kind == 'ankan' }

        ankan_melds.map do |meld|
          suit = meld.tile.suit.first
          number = meld.tile.number
          "#{suit}#{number}#{number}#{number}#{number}"
        end.compact.uniq
      end
  end
end

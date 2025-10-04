# frozen_string_literal: true

module GameTestHelper
  RELATION_BY_MARK = { '-' => :shimocha, '=' => :toimen, '+' => :kamicha }.freeze
  NORMAL_RELATION_INDEX = { shimocha: 0, toimen: 1, kamicha: 2 }.freeze
  ABNORMAL_RELATION_INDEX = { shimocha: 0, toimen: 1, kamicha: 3 }.freeze
  SUIT_NAMES  = { 'm' => 'manzu', 'p' => 'pinzu', 's' => 'souzu', 'z' => 'zihai' }.freeze
  ZIHAI_NAMES = %w[ton nan sha pei haku hatsu chun].freeze
  KANS        = %w[daiminkan ankan kakan].freeze
  CHI_RE = /\A([mps])(?:[1-9]\+[1-9]{2}|[1-9]{2}\+[1-9]|[1-9]{3}\+)\z/
  MPS_TRIPLET_OR_QUAD_RE = /\A(?<suit>[mps])(?<number>[1-9])\k<number>{2,3}(?<rel>[+=-])?\z/
  Z_TRIPLET_OR_QUAD_RE   = /\A(?<suit>z)(?<number>[1-7])\k<number>{2,3}(?<rel>[+=-])?\z/


  def find_game_from_url
    path = URI.parse(response.location).path
    game_id = path[%r{\A/games/(\d+)/play\z}, 1].to_i
    Game.find(game_id)
  end

  def set_user_turn(game)
    game.advance_current_player! while game.current_player.ai?
  end

  def set_opponent_turn(game)
    game.advance_current_player! unless game.current_player.ai?
  end

  def assign_host_player(player, game)
    host_seat_number = game.latest_round.host_seat_number
    game.players.find_by(seat_order: host_seat_number).update!(seat_order: player.seat_order)
    player.update!(seat_order: host_seat_number)
  end

  def build_situational_yaku_list(tenhou: false, chiihou: false, riichi: false, double_riichi: false, ippatsu: false, haitei: false, houtei: false, rinshan: false, chankan: false)
    { tenhou:, chiihou:, riichi:, double_riichi:, ippatsu:, haitei:, houtei:, rinshan:, chankan: }
  end

  def set_hands(pattern, player, drawn: true, rinshan: false)
    player.current_state.hands.delete_all
    game = player.game

    pattern.delete(' ').scan(/([mpsz])([0-9]+)/) do |suit, numbers|
      suit_name = SUIT_NAMES[suit].to_sym
      numbers.chars.each do |number|
        n = number.to_i

        tile = game.tiles.joins(:base_tile).find_by!(base_tile: { suit: suit_name, number: n })
        player.current_state.hands.create!(tile:)
      end
    end
    player.hands.last.update!(drawn:, rinshan:)
    player.hands
  end

  def set_rivers(pattern, player, tsumogiri: false, stolen: false)
    player.current_state.rivers.delete_all
    game = player.game

    pattern.delete(' ').scan(/([mpsz])([0-9]+)/) do |suit, numbers|
      suit_name = SUIT_NAMES[suit].to_sym
      numbers.chars.each do |number|
        n = number.to_i

        tile = game.tiles.joins(:base_tile).find_by!(base_tile: { suit: suit_name, number: n })
        player.current_state.rivers.create!(tile:, tsumogiri:, stolen:)
      end
    end
    player.rivers
  end

  # patterns: String または Array<String>
  # 例) 'z111= m1+23 p12+3 z1111='  /  ['z111=', 'm1+23']
  def set_melds(patterns, player)
    meld_combos = Array(patterns).join(' ').split(/[,\s]+/).reject(&:empty?)

    meld_combos.flat_map do |meld_combo|
      case meld_combo
      when CHI_RE
        suit       = meld_combo[0]
        from_index = meld_combo.index('+') - 2
        numbers    = meld_combo[1..].delete('+').chars.map!(&:to_i)

        build_meld_set(
          kind: :chi,
          suit:,
          numbers:,
          from_index:,
          relation: :kamicha,
          player:
        )

      when MPS_TRIPLET_OR_QUAD_RE, Z_TRIPLET_OR_QUAD_RE
        suit     = Regexp.last_match[:suit]
        number   = Regexp.last_match[:number].to_i
        mark     = Regexp.last_match[:rel]
        tiles_n  = meld_combo.count('0-9')

        kind =
          if tiles_n == 4
            mark ? :daiminkan : :ankan
          else
            :pon
          end

        relation = mark && RELATION_BY_MARK[mark]
        from_index = KANS.include?(kind) ? ABNORMAL_RELATION_INDEX[relation] : NORMAL_RELATION_INDEX[relation]

        build_meld_set(
          kind:,
          suit:,
          numbers: Array.new(tiles_n, number),
          relation:,
          from_index:,
          player:
        )
      end
    end

    player.current_state.melds
  end

  def build_meld_set(kind:, suit:, numbers:, from_index:, relation:, player:)
    tiles = player.game.tiles
    suit_name = SUIT_NAMES[suit].to_sym

    numbers.each_with_index.map do |number, position|
      tile = tiles.joins(:base_tile).find_by!(base_tile: { suit: suit_name, number: number })
      from = relation if relation && position == from_index
      player.current_state.melds.create!(tile:, kind:, position:, from:)
    end
  end

  def assign_draw_tile(tile_name, game)
    draw_count = game.draw_count
    suit = SUIT_NAMES[tile_name[0]]
    number = tile_name[1].to_i

    target_tile = game.latest_honba.tile_orders.joins(tile: :base_tile).find_by(base_tiles: { number:, suit: })
    game.latest_honba.tile_orders.find_by(order: draw_count).update!(order: target_tile.order)
    target_tile.update!(order: draw_count)
  end
end

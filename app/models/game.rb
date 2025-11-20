# frozen_string_literal: true

class Game < ApplicationRecord
  TILES_PER_KIND = 4
  AKA_DORA_TILE_CODES = [ 4, 13, 22 ].freeze # 5萬、5筒、5索の牌コード
  INITIAL_HAND_SIZE = 13
  PLAYERS_COUNT = 4
  RELATION_ORDER = { shimocha: 0, toimen: 1, kamicha: 2 }.freeze
  RIICHI_BONUS = 1000
  HONBA_BONUS = 300
  TENPAI_POINT = {
    0 => 0,
    1 => 3000,
    2 => 1500,
    3 => 1000,
    4 => 0
  }.freeze
  FINAL_ROUND_NUMBER = 7
  MAX_DORA_COUNT = 5

  belongs_to :game_mode

  has_many :players, -> { order(:seat_order) }, dependent: :destroy
  has_many :results, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :rounds, -> { order(:number) }, dependent: :destroy
  has_many :tiles, dependent: :destroy

  validates :game_mode, presence: true

  after_create :create_tiles_and_round

  def setup_players(user, ai)
    all_players = [ user, ai, ai, ai ].shuffle

    all_players.each_with_index do |player, seat_order|
      new_player = if user.id == player.id
        players.create!(user: player, seat_order:)
      else
        players.create!(ai: player, seat_order:)
      end
      new_player.game_records.create!(honba: latest_honba)
    end
  end

  def apply_game_mode
    if game_mode.mode_type == 'final_round'
      assign_random_scores!
      latest_round.update!(number: FINAL_ROUND_NUMBER)
    end
  end

  def deal_initial_hands
    players.each do |player|
      player.player_states.create!(step: current_step)

      INITIAL_HAND_SIZE.times do |_|
        top_tile = latest_honba.top_tile
        player.receive(top_tile)
        increase_draw_count
      end
    end
  end

  def user_player
    if players.loaded?
      players.detect(&:user?)
    else
      players.users.first
    end
  end

  def ais
    if players.loaded?
      players.select(&:ai?)
    else
      players.ais.to_a
    end
  end

  def host
    if players.loaded?
      players.detect(&:host?)
    else
      players.find_by!(seat_order: latest_round.host_seat_number)
    end
  end

  def children
    if players.loaded?
      players.select { |player| !player.host? }
    else
      players.where.not(seat_order: latest_round.host_seat_number).to_a
    end
  end

  def current_player
    if players.loaded?
      players.detect { |player| player.seat_order == current_seat_number }
    else
      players.find_by!(seat_order: current_seat_number)
    end
  end

  def current_step
    if latest_honba.steps.loaded?
      latest_honba.steps.detect { |step| step.number == current_step_number }
    else
      latest_honba.steps.find_by!(number: current_step_number)
    end
  end

  def dora_indicator_tiles
    latest_honba.dora_indicator_tiles.values_at(...MAX_DORA_COUNT)
  end

  def latest_round
    rounds.last
  end

  def latest_honba
    latest_round.latest_honba
  end

  def current_round_name
    latest_round.name
  end

  def round_wind_number
    latest_round.wind_number
  end

  def current_honba_name
    latest_honba.name
  end

  def riichi_stick_count
    latest_honba.riichi_stick_count
  end

  def remaining_tile_count
    latest_honba.remaining_tile_count
  end

  def live_wall_empty?
    remaining_tile_count.zero?
  end

  def draw_count
    latest_honba.draw_count
  end

  def advance_current_player!
    next_seat_number = (current_seat_number + 1) % PLAYERS_COUNT
    update!(current_seat_number: next_seat_number)
  end

  def advance_to_player!(player)
    update!(current_seat_number: player.seat_order)
  end

  def draw_for_current_player
    top_tile = latest_honba.top_tile
    increase_draw_count
    next_step = advance_step!
    current_player.draw(top_tile, next_step)
  end

  def discard_for_current_player(hand_id)
    next_step = advance_step!
    current_player.discard(hand_id, next_step)
  end

  def apply_furo(furo_type, furo_ids, discarded_tile_id)
    next_step = advance_step!
    current_player.stolen(discarded_tile_id, next_step)
    user_player.steal(current_player, furo_type, furo_ids, discarded_tile_id, next_step)
  end

  def advance_next_round!(ryukyoku: false)
    next_honba_number = ryukyoku ? latest_honba.number + 1 : 0
    riichi_stick_count = ryukyoku ? latest_honba.riichi_stick_count : 0
    next_round_number = latest_round.number + 1
    rounds.create!(number: next_round_number)
    latest_honba.update!(number: next_honba_number, riichi_stick_count:)

    next_seat_number = next_round_number % PLAYERS_COUNT
    update!(current_seat_number: next_seat_number)
    update!(current_step_number: 0)
    create_game_records
  end

  def advance_next_honba!(ryukyoku: false)
    next_honba_number = latest_honba.number + 1
    riichi_stick_count = ryukyoku ? latest_honba.riichi_stick_count : 0
    latest_round.honbas.create!(number: next_honba_number, riichi_stick_count:)

    seat_number = latest_round.number % PLAYERS_COUNT
    update!(current_seat_number: seat_number)
    update!(current_step_number: 0)
    create_game_records
  end

  def find_ron_players(tile)
    other_players.map do |player|
      player.can_ron?(tile) ? player : next
    end.compact
  end

  def build_ron_score_statements(discarded_tile_id, ron_player_ids)
    ron_players = players.where(id: ron_player_ids)
    tile = tiles.find(discarded_tile_id)
    score_statement_table = {}

    ron_players.each do |player|
      score_statements = player.score_statements(tile:)
      score_statement_table[player.id] = score_statements
    end
    score_statement_table
  end

  def give_ron_point(score_statement_table)
    score_statement_table.each do |player_id, score_statements|
      player = players.find(player_id)
      point = PointCalculator.calculate_point(score_statements, player)
      player.add_point(point[:receiving])
      current_player.add_point(point[:payment])
    end
  end

  def give_tsumo_point
    score_statements = current_player.score_statements
    point = PointCalculator.calculate_point(score_statements, current_player)
    current_player.add_point(point[:receiving])

    other_players.each do |player|
      payment = player.host? ? point[:payment][:host] : point[:payment][:child]
      player.add_point(payment)
    end
  end

  def give_bonus_point(ron_player_ids: false)
    give_riichi_bonus_point(ron_player_ids)
    give_honba_bonus_point(ron_player_ids)
  end

  def give_tenpai_point
    tenpai_players = players.select { |player| player.tenpai? }
    point = TENPAI_POINT.fetch(tenpai_players.count)
    tenpai_players.each { |player| player.add_point(point) }

    no_ten_players = players.select { |player| !player.tenpai? }
    payment = -TENPAI_POINT.fetch(no_ten_players.count)
    no_ten_players.each { |player| player.add_point(payment) }
  end

  def host_winner?
    host.point.positive?
  end

  def can_undo?
    current_step_number > 0
  end

  def can_redo?
    current_step_number < latest_step_number
  end

  def undo_step
    update!(current_step_number: current_step_number - 1)
  end

  def redo_step
    update!(current_step_number: current_step_number + 1)
  end

  def destroy_future_steps
    future_steps = latest_honba.steps.where('number > ?', current_step_number)
    future_steps.destroy_all
  end

  def sync_current_seat
    target_seat_number = current_step.player_states.first.player.seat_order
    update!(current_seat_number: target_seat_number)
  end

  def sync_draw_count
    latest_honba.update!(draw_count: current_step.draw_count)
  end

  def sync_kan_count
    latest_honba.update!(kan_count: current_step.kan_count)
  end

  def sync_riichi_count
    latest_honba.update!(riichi_stick_count: current_step.riichi_stick_count)
  end

  def game_end?
    latest_round.number + 1 > game_mode.round_count
  end

  def ranked_players
    if players.loaded?
      players.sort_by { |player| -(player.score + player.point) }
    else
      players.includes(:game_records).to_a.sort_by { |player| -(player.score + player.point) }
    end
  end

  def rankings
    ranked_players.each_with_index.to_h { |player, index| [ player.id, index + 1 ] }
  end

  def reset_point
    players.each { |player| player.latest_game_record.update!(point: 0) }
  end

  private

    def create_tiles_and_round
      setup_tiles
      rounds.create!
    end

    def setup_tiles
      base_tiles = BaseTile.all.index_by(&:code)

      base_tiles.keys.each do |code|
        base_tile = base_tiles[code]
        TILES_PER_KIND.times do |kind|
          is_aka_dora = aka_dora_tile?(code, kind)
          tiles.create!(kind:, aka: is_aka_dora, base_tile:)
        end
      end
    end

    def aka_dora_tile?(code, kind)
      AKA_DORA_TILE_CODES.include?(code) && kind.zero?
    end

    def assign_random_scores!
      # 5000点〜45000点の間でスコアを割り振る
      # 合計スコアが100000点となる
      pair_score = 50_000
      min = 50
      max = 450

      random_scores = 2.times.map do |_|
                        random_score_1 = rand(min..max) * 100
                        random_score_2 = pair_score - random_score_1
                        [ random_score_1, random_score_2 ]
                      end.flatten.shuffle

      players.each_with_index do |player, index|
        random_score = random_scores[index]
        player.game_records.last.update!(score: random_score)
      end
    end

    def increase_draw_count
      latest_honba.increment!(:draw_count)
    end

    def advance_step!
      next_step_number = current_step_number + 1
      update!(current_step_number: next_step_number)
      latest_honba.steps.create!(number: next_step_number)
    end

    def other_players
      if players.loaded?
        players.select { |player| player.seat_order != current_seat_number }
      else
        players.where.not(seat_order: current_seat_number).to_a
      end
    end

    def find_riichi_bonus_winner(ron_player_ids)
      winner_players = players.where(id: ron_player_ids)
      winner_players.min_by { |player| RELATION_ORDER.fetch(player.relation_from_current_player) }
    end

    def create_game_records
      players.each do |player|
        score = player.score + player.point
        player.game_records.create!(score:, honba: latest_honba)
      end
    end

    def give_riichi_bonus_point(ron_player_ids)
      winner = ron_player_ids ? find_riichi_bonus_winner(ron_player_ids) : current_player
      riichi_bonus = latest_honba.riichi_stick_count * RIICHI_BONUS
      winner.add_point(riichi_bonus)
    end

    def give_honba_bonus_point(ron_player_ids)
      winners = ron_player_ids ? players.where(id: ron_player_ids) : [ current_player ]
      losers  = ron_player_ids ? [ current_player ] : other_players
      honba_bonus  = latest_honba.number * HONBA_BONUS
      winners.each { |winner| winner.add_point(honba_bonus) }

      bonus_payment = losers.size == 1 ? -honba_bonus * winners.count : -honba_bonus / losers.count
      losers.each { |loser| loser.add_point(bonus_payment) }
    end

    def latest_step_number
      latest_honba.steps.maximum(:number)
    end
end

# frozen_string_literal: true

class Game < ApplicationRecord
  TILES_PER_KIND = 4
  AKA_DORA_TILE_CODES = [ 4, 13, 22 ] # 5萬、5筒、5索の牌コード
  INITIAL_HAND_SIZE = 13
  PLAYERS_COUNT = 4

  belongs_to :game_mode

  has_many :players, dependent: :destroy
  has_many :results, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :rounds, dependent: :destroy
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

  def deal_initial_hands
    players.ordered.each do |player|
      player.player_states.create!(step: current_step)

      INITIAL_HAND_SIZE.times do |_|
        player.receive(top_tile)
        increase_draw_count
      end
    end
  end

  def user_player
    players.users.first
  end

  def opponents
    players.ais
  end

  def current_player
    players.find_by!(seat_order: current_seat_number)
  end

  def advance_current_player!
    next_seat_number = (current_seat_number + 1) % PLAYERS_COUNT
    update!(current_seat_number: next_seat_number)
  end

  def advance_to_player!(player)
    update!(current_seat_number: player.seat_order)
  end

  def draw_count
    latest_honba.draw_count
  end

  def draw_for_current_player
    advance_step!
    current_player.draw(top_tile, current_step)
    increase_draw_count
  end

  def discard_for_current_player(hand_id)
    advance_step!
    current_player.discard(hand_id, current_step)
  end

  def latest_round
    rounds.order(:number).last
  end

  def latest_honba
    latest_round.latest_honba
  end

  def current_round_name
    latest_round.name
  end

  def current_honba_name
    latest_honba.name
  end

  def remaining_tile_count
    latest_honba.remaining_tile_count
  end

  def dora_indicator_tiles
    latest_honba.dora_indicator_tiles.values_at(..4)
  end

  def host_player
    players.find_by!(seat_order: latest_round.host_seat_number)
  end

  def riichi_stick_count
    latest_honba.riichi_stick_count
  end

  def apply_furo(furo_type, furo_ids, discarded_tile_id)
    furo_tiles = furo_ids.map { |furo_id| user_player.hands.find(furo_id).tile }
    discarded_tile = tiles.find(discarded_tile_id)
    advance_step!
    current_player.stolen(discarded_tile, current_step)
    user_player.steal(current_player, furo_type, furo_tiles, discarded_tile, current_step)
  end

  def round_wind_number
    latest_round.wind_number
  end

  def advance_next_round!
    next_round_number = latest_round.number + 1
    rounds.create!(number: next_round_number)

    next_seat_number = next_round_number % PLAYERS_COUNT
    update!(current_seat_number: next_seat_number)
    update!(current_step_number: 0)
  end

  def advance_next_honba!
    next_honba_number = latest_honba.number + 1
    riichi_stick_count = latest_honba.riichi_stick_count
    latest_round.honbas.create!(number: next_honba_number, riichi_stick_count: riichi_stick_count)

    seat_number = latest_round.number % PLAYERS_COUNT
    update!(current_seat_number: seat_number)
    update!(current_step_number: 0)
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
      game_mode.aka_dora? && AKA_DORA_TILE_CODES.include?(code) && kind.zero?
    end

    def current_step
      latest_honba.find_current_step(current_step_number)
    end

    def top_tile
      latest_honba.top_tile
    end

    def increase_draw_count
      latest_honba.increment!(:draw_count)
    end

    def advance_step!
      next_step_number = current_step_number + 1
      update!(current_step_number: next_step_number)
      latest_honba.steps.create!(number: next_step_number)
    end
end

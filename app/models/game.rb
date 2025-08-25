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
      new_player.create_game_record(current_honba)
      new_player.create_state(current_step)
    end
  end

  def deal_initial_hands
    players.ordered.each do |player|
      INITIAL_HAND_SIZE.times do |_|
        player.receive(top_tile)
        increase_draw_count
      end
    end
  end

  def user_player
    players.where.not(user_id: nil).first
  end

  def opponents
    players.where.not(ai_id: nil)
  end

  def current_player
    players.find_by!(seat_order: current_seat_number)
  end

  def advance_current_player!
    next_seat_number = (current_seat_number + 1) % PLAYERS_COUNT
    update!(current_seat_number: next_seat_number)
  end

  def draw_count
    current_honba.draw_count
  end

  def draw_for_current_player
    current_player.draw(top_tile, next_step)
    increase_draw_count
  end

  def discard_for_current_player(tile_id)
    current_player.discard(tile_id, next_step)
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

    def current_round
      rounds.order(:number).last
    end

    def current_honba
      current_round.current_honba
    end

    def current_turn
      current_honba.current_turn
    end

    def current_step
      current_turn.current_step
    end

    def next_step_number
      current_step.number + 1
    end

    def top_tile
      current_honba.top_tile
    end

    def host
      players.find_by(seat_order: current_round.host_position)
    end

    def increase_draw_count
      current_honba.increment!(:draw_count)
    end

    def next_step
      next_step_number = current_step.number + 1
      current_turn.steps.create!(number: next_step_number)
    end
end

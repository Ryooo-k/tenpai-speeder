# frozen_string_literal: true

class Game < ApplicationRecord
  TILES_PER_KIND = 4
  AKA_DORA_TILE_CODES = [ 4, 13, 22 ] # 5萬、5筒、5索の牌コード
  INITIAL_HAND_SIZE = 13

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
      new_player.create_score(current_honba)
      new_player.create_state(current_step)
    end
  end

  def deal_initial_hands
    players.ordered.each do |player|
      INITIAL_HAND_SIZE.times do |_|
        tile = current_honba.top_tile
        player.receive(tile)
      end
    end
  end

  def current_honba
    rounds.last.honbas.last
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
    rounds.last.honbas.last.turns.last.steps.last
  end
end

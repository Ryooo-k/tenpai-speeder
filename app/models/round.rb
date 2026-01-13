# frozen_string_literal: true

class Round < ApplicationRecord
  belongs_to :game

  has_many :honbas, -> { order(:number) }, dependent: :destroy

  validates :number, presence: true

  after_create :create_honba

  def name
    case number
    when 0 then '東一局'
    when 1 then '東二局'
    when 2 then '東三局'
    when 3 then '東四局'
    when 4 then '南一局'
    when 5 then '南二局'
    when 6 then '南三局'
    when 7 then '南四局'
    end
  end

  def wind_number
    case number
    when 0..3 then Mahjong::Constants::TON_WIND_NUMBER
    when 4..7 then Mahjong::Constants::NAN_WIND_NUMBER
    end
  end

  def host_seat_number
    number % Mahjong::Constants::PLAYERS_COUNT
  end

  def latest_honba
    honbas.last
  end

  private

    def create_honba
      honbas.create!
    end
end

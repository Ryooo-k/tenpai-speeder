# frozen_string_literal: true

class Round < ApplicationRecord
  belongs_to :game

  has_many :honbas, dependent: :destroy

  validates :game, presence: true
  validates :number, presence: true
  validates :host_position, presence: true

  after_create :create_honba

  def current_honba
    honbas.order(:number).last
  end

  private

    def create_honba
      honbas.create!
    end
end

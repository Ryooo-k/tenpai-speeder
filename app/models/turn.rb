# frozen_string_literal: true

class Turn < ApplicationRecord
  belongs_to :honba

  has_many :steps, dependent: :destroy

  validates :number, presence: true
  validates :honba, presence: true

  after_create :create_step

  private

    def create_step
      steps.create!
    end
end

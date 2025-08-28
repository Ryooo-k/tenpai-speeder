# frozen_string_literal: true

class Turn < ApplicationRecord
  belongs_to :honba

  has_many :steps, dependent: :destroy

  validates :honba, presence: true
  validates :number, presence: true

  after_create :create_step

  def current_step(number: nil)
    steps.order(:number).last
  end

  private

    def create_step
      steps.create!
    end
end

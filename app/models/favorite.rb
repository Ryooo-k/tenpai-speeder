# frozen_string_literal: true

class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :game

  validate :user_must_be_oauth

  private

    def user_must_be_oauth
      return if user&.provider.present?
      errors.add(:base, 'お気に入り機能を使うにはSNSログインが必要です')
    end
end

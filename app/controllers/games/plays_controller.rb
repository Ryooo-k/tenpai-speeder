# frozen_string_literal: true

class Games::PlaysController < ApplicationController
  include Games::PlaySupport

  before_action :set_game
  before_action :set_instance_variable, only: :show

  def show
  end
end

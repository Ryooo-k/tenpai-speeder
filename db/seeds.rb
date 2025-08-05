# frozen_string_literal: true

require 'active_record/fixtures'

tables = %i[
  ais
  users
  game_modes
  base_tiles
]

ActiveRecord::FixtureSet.create_fixtures 'db/fixtures', tables

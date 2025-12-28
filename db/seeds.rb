# frozen_string_literal: true

require 'active_record/fixtures'

normal_fixtures = %i[
  ais
  users
  game_modes
  base_tiles
]

ActiveRecord::FixtureSet.create_fixtures 'db/fixtures', normal_fixtures

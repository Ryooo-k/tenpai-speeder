# frozen_string_literal: true

require 'active_record/fixtures'

normal_fixtures = %i[
  ais
  users
  game_modes
  base_tiles
]

design_preview_fixtures = %i[
  games
  tiles
  rounds
  honbas
  steps
  tile_orders
  players
  player_states
  hands
  melds
  rivers
  game_records
]

ActiveRecord::FixtureSet.create_fixtures 'db/fixtures', normal_fixtures
ActiveRecord::FixtureSet.create_fixtures 'db/fixtures/design_preview', design_preview_fixtures

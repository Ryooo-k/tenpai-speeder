# frozen_string_literal: true

require 'yaml'

namespace :db do
  namespace :seed do
    desc 'Upsert game_modes from db/fixtures/game_modes.yml'
    task game_modes: :environment do
      fixture_path = Rails.root.join('db', 'fixtures', 'game_modes.yml')
      modes = YAML.load_file(fixture_path)

      modes.each_value do |attrs|
        game_mode = GameMode.find_or_initialize_by(name: attrs['name'])
        game_mode.update!(attrs)
      end
    end
  end
end

namespace :db do
  namespace :seed do
    desc 'Upsert ais from db/fixtures/ais.yml'
    task ais: :environment do
      fixture_path = Rails.root.join('db', 'fixtures', 'ais.yml')
      ais = YAML.load_file(fixture_path)

      ais.each_value do |attrs|
        ai = Ai.find_or_initialize_by(name: attrs['name'])
        ai.update!(attrs)
      end
    end
  end
end

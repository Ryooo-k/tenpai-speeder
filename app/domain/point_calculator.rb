# frozen_string_literal: true

module PointCalculator
  HOST_TSUMO_POINT_TABLE = {
    '1' => {
      '30'  => { receiving:  1500, payment: { child:  -500, host: 0 } },
      '40'  => { receiving:  2100, payment: { child:  -700, host: 0 } },
      '50'  => { receiving:  2400, payment: { child:  -800, host: 0 } },
      '60'  => { receiving:  3000, payment: { child: -1000, host: 0 } },
      '70'  => { receiving:  3600, payment: { child: -1200, host: 0 } },
      '80'  => { receiving:  3900, payment: { child: -1300, host: 0 } },
      '90'  => { receiving:  4500, payment: { child: -1500, host: 0 } },
      '100' => { receiving:  4800, payment: { child: -1600, host: 0 } },
      '110' => { receiving:  5400, payment: { child: -1800, host: 0 } }
    },
    '2' => {
      '20'  => { receiving:  2100, payment: { child:  -700, host: 0 } },
      '30'  => { receiving:  3000, payment: { child: -1000, host: 0 } },
      '40'  => { receiving:  3900, payment: { child: -1300, host: 0 } },
      '50'  => { receiving:  4800, payment: { child: -1600, host: 0 } },
      '60'  => { receiving:  6000, payment: { child: -2000, host: 0 } },
      '70'  => { receiving:  6900, payment: { child: -2300, host: 0 } },
      '80'  => { receiving:  7800, payment: { child: -2600, host: 0 } },
      '90'  => { receiving:  8700, payment: { child: -2900, host: 0 } },
      '100' => { receiving:  9600, payment: { child: -3200, host: 0 } },
      '110' => { receiving: 10800, payment: { child: -3600, host: 0 } }
    },
    '3' => {
      '20'  => { receiving:  3900, payment: { child: -1300, host: 0 } },
      '25'  => { receiving:  4800, payment: { child: -1600, host: 0 } },
      '30'  => { receiving:  6000, payment: { child: -2000, host: 0 } },
      '40'  => { receiving:  7800, payment: { child: -2600, host: 0 } },
      '50'  => { receiving:  9600, payment: { child: -3200, host: 0 } },
      '60'  => { receiving: 12000, payment: { child: -4000, host: 0 } },
      '70'  => { receiving: 12000, payment: { child: -4000, host: 0 } },
      '80'  => { receiving: 12000, payment: { child: -4000, host: 0 } },
      '90'  => { receiving: 12000, payment: { child: -4000, host: 0 } },
      '100' => { receiving: 12000, payment: { child: -4000, host: 0 } },
      '110' => { receiving: 12000, payment: { child: -4000, host: 0 } }
    },
    '4' => {
      '20'  => { receiving:  7800, payment: { child: -2600, host: 0 } },
      '25'  => { receiving:  9600, payment: { child: -3200, host: 0 } },
      '30'  => { receiving: 12000, payment: { child: -4000, host: 0 } },
      '40'  => { receiving: 12000, payment: { child: -4000, host: 0 } },
      '50'  => { receiving: 12000, payment: { child: -4000, host: 0 } },
      '60'  => { receiving: 12000, payment: { child: -4000, host: 0 } },
      '70'  => { receiving: 12000, payment: { child: -4000, host: 0 } },
      '80'  => { receiving: 12000, payment: { child: -4000, host: 0 } },
      '90'  => { receiving: 12000, payment: { child: -4000, host: 0 } },
      '100' => { receiving: 12000, payment: { child: -4000, host: 0 } },
      '110' => { receiving: 12000, payment: { child: -4000, host: 0 } }
    },
    '5'  => { '*' => { receiving: 12000, payment: { child:  -4000, host: 0 } } },
    '6'  => { '*' => { receiving: 18000, payment: { child:  -6000, host: 0 } } },
    '7'  => { '*' => { receiving: 18000, payment: { child:  -6000, host: 0 } } },
    '8'  => { '*' => { receiving: 24000, payment: { child:  -8000, host: 0 } } },
    '9'  => { '*' => { receiving: 24000, payment: { child:  -8000, host: 0 } } },
    '10' => { '*' => { receiving: 24000, payment: { child:  -8000, host: 0 } } },
    '11' => { '*' => { receiving: 36000, payment: { child: -12000, host: 0 } } },
    '12' => { '*' => { receiving: 36000, payment: { child: -12000, host: 0 } } },
    '13' => { '*' => { receiving: 48000, payment: { child: -16000, host: 0 } } }
  }

  CHILD_TSUMO_POINT_TABLE = {
    '1' => {
      '30'  => { receiving: 1100, payment: { child:  -300, host:  -500 } },
      '40'  => { receiving: 1500, payment: { child:  -400, host:  -700 } },
      '50'  => { receiving: 1600, payment: { child:  -400, host:  -800 } },
      '60'  => { receiving: 2000, payment: { child:  -500, host: -1000 } },
      '70'  => { receiving: 2400, payment: { child:  -600, host: -1200 } },
      '80'  => { receiving: 2700, payment: { child:  -700, host: -1300 } },
      '90'  => { receiving: 3100, payment: { child:  -800, host: -1500 } },
      '100' => { receiving: 3200, payment: { child:  -800, host: -1600 } },
      '110' => { receiving: 3600, payment: { child:  -900, host: -1800 } }
    },
    '2' => {
      '20'  => { receiving: 1500, payment: { child:  -400, host:  -700 } },
      '30'  => { receiving: 2000, payment: { child:  -500, host: -1000 } },
      '40'  => { receiving: 2700, payment: { child:  -700, host: -1300 } },
      '50'  => { receiving: 3200, payment: { child:  -800, host: -1600 } },
      '60'  => { receiving: 4000, payment: { child: -1000, host: -2000 } },
      '70'  => { receiving: 4700, payment: { child: -1200, host: -2300 } },
      '80'  => { receiving: 5200, payment: { child: -1300, host: -2600 } },
      '90'  => { receiving: 5900, payment: { child: -1500, host: -2900 } },
      '100' => { receiving: 6400, payment: { child: -1600, host: -3200 } },
      '110' => { receiving: 7200, payment: { child: -1800, host: -3600 } }
    },
    '3' => {
      '20'  => { receiving: 2700, payment: { child:  -700, host: -1300 } },
      '25'  => { receiving: 3200, payment: { child:  -800, host: -1600 } },
      '30'  => { receiving: 4000, payment: { child: -1000, host: -2000 } },
      '40'  => { receiving: 5200, payment: { child: -1300, host: -2600 } },
      '50'  => { receiving: 6400, payment: { child: -1600, host: -3200 } },
      '60'  => { receiving: 8000, payment: { child: -2000, host: -4000 } },
      '70'  => { receiving: 8000, payment: { child: -2000, host: -4000 } },
      '80'  => { receiving: 8000, payment: { child: -2000, host: -4000 } },
      '90'  => { receiving: 8000, payment: { child: -2000, host: -4000 } },
      '100' => { receiving: 8000, payment: { child: -2000, host: -4000 } },
      '110' => { receiving: 8000, payment: { child: -2000, host: -4000 } }
    },
    '4' => {
      '20'  => { receiving: 5200, payment: { child: -1300, host: -2600 } },
      '25'  => { receiving: 6400, payment: { child: -1600, host: -3200 } },
      '30'  => { receiving: 8000, payment: { child: -2000, host: -4000 } },
      '40'  => { receiving: 8000, payment: { child: -2000, host: -4000 } },
      '50'  => { receiving: 8000, payment: { child: -2000, host: -4000 } },
      '60'  => { receiving: 8000, payment: { child: -2000, host: -4000 } },
      '70'  => { receiving: 8000, payment: { child: -2000, host: -4000 } },
      '80'  => { receiving: 8000, payment: { child: -2000, host: -4000 } },
      '90'  => { receiving: 8000, payment: { child: -2000, host: -4000 } },
      '100' => { receiving: 8000, payment: { child: -2000, host: -4000 } },
      '110' => { receiving: 8000, payment: { child: -2000, host: -4000 } }
    },
    '5'  => { '*' => { receiving:  8000, payment: { child: -2000, host:  -4000 } } },
    '6'  => { '*' => { receiving: 12000, payment: { child: -3000, host:  -6000 } } },
    '7'  => { '*' => { receiving: 12000, payment: { child: -3000, host:  -6000 } } },
    '8'  => { '*' => { receiving: 16000, payment: { child: -4000, host:  -8000 } } },
    '9'  => { '*' => { receiving: 16000, payment: { child: -4000, host:  -8000 } } },
    '10' => { '*' => { receiving: 16000, payment: { child: -4000, host:  -8000 } } },
    '11' => { '*' => { receiving: 24000, payment: { child: -6000, host: -12000 } } },
    '12' => { '*' => { receiving: 24000, payment: { child: -6000, host: -12000 } } },
    '13' => { '*' => { receiving: 32000, payment: { child: -8000, host: -16000 } } }
  }

  HOST_RON_POINT_TABLE = {
    '1' => {
      '30'  => { receiving: 1500, payment: -1500 },
      '40'  => { receiving: 2000, payment: -2000 },
      '50'  => { receiving: 2400, payment: -2400 },
      '60'  => { receiving: 2900, payment: -2900 },
      '70'  => { receiving: 3400, payment: -3400 },
      '80'  => { receiving: 3900, payment: -3900 },
      '90'  => { receiving: 4400, payment: -4400 },
      '100' => { receiving: 4800, payment: -4800 },
      '110' => { receiving: 5300, payment: -5300 }
    },
    '2' => {
      '25'  => { receiving:  2400, payment: -2400 },
      '30'  => { receiving:  2900, payment: -2900 },
      '40'  => { receiving:  3900, payment: -3900 },
      '50'  => { receiving:  4800, payment: -4800 },
      '60'  => { receiving:  5800, payment: -5800 },
      '70'  => { receiving:  6800, payment: -6800 },
      '80'  => { receiving:  7700, payment: -7700 },
      '90'  => { receiving:  8700, payment: -8700 },
      '100' => { receiving:  9600, payment: -9600 },
      '110' => { receiving: 10600, payment: -10600 }
    },
    '3' => {
      '25'  => { receiving:  4800, payment:  -4800 },
      '30'  => { receiving:  5800, payment:  -5800 },
      '40'  => { receiving:  7700, payment:  -7700 },
      '50'  => { receiving:  9600, payment:  -9600 },
      '60'  => { receiving: 12000, payment: -12000 },
      '70'  => { receiving: 12000, payment: -12000 },
      '80'  => { receiving: 12000, payment: -12000 },
      '90'  => { receiving: 12000, payment: -12000 },
      '100' => { receiving: 12000, payment: -12000 },
      '110' => { receiving: 12000, payment: -12000 }
    },
    '4' => {
      '25'  => { receiving:  9600, payment:  -9600 },
      '30'  => { receiving: 12000, payment: -12000 },
      '40'  => { receiving: 12000, payment: -12000 },
      '50'  => { receiving: 12000, payment: -12000 },
      '60'  => { receiving: 12000, payment: -12000 },
      '70'  => { receiving: 12000, payment: -12000 },
      '80'  => { receiving: 12000, payment: -12000 },
      '90'  => { receiving: 12000, payment: -12000 },
      '100' => { receiving: 12000, payment: -12000 },
      '110' => { receiving: 12000, payment: -12000 }
    },
    '5'  => { '*' => { receiving: 12000, payment: -12000 } },
    '6'  => { '*' => { receiving: 16000, payment: -16000 } },
    '7'  => { '*' => { receiving: 16000, payment: -16000 } },
    '8'  => { '*' => { receiving: 24000, payment: -24000 } },
    '9'  => { '*' => { receiving: 24000, payment: -24000 } },
    '10' => { '*' => { receiving: 24000, payment: -24000 } },
    '11' => { '*' => { receiving: 36000, payment: -36000 } },
    '12' => { '*' => { receiving: 36000, payment: -36000 } },
    '13' => { '*' => { receiving: 48000, payment: -48000 } }
  }

  CHILD_RON_POINT_TABLE = {
    '1' => {
      '30'  => { receiving: 1000, payment: -1000 },
      '40'  => { receiving: 1300, payment: -1300 },
      '50'  => { receiving: 1600, payment: -1600 },
      '60'  => { receiving: 2000, payment: -2000 },
      '70'  => { receiving: 2300, payment: -2300 },
      '80'  => { receiving: 2600, payment: -2600 },
      '90'  => { receiving: 2900, payment: -2900 },
      '100' => { receiving: 3200, payment: -3200 },
      '110' => { receiving: 3600, payment: -3600 }
    },
    '2' => {
      '25'  => { receiving: 1600, payment: -1600 },
      '30'  => { receiving: 2000, payment: -2000 },
      '40'  => { receiving: 2600, payment: -2600 },
      '50'  => { receiving: 3200, payment: -3200 },
      '60'  => { receiving: 3900, payment: -3900 },
      '70'  => { receiving: 4500, payment: -4500 },
      '80'  => { receiving: 5200, payment: -5200 },
      '90'  => { receiving: 5800, payment: -5800 },
      '100' => { receiving: 6400, payment: -6400 },
      '110' => { receiving: 7100, payment: -7100 }
    },
    '3' => {
      '25'  => { receiving: 3200, payment: -3200 },
      '30'  => { receiving: 3900, payment: -3900 },
      '40'  => { receiving: 5200, payment: -5200 },
      '50'  => { receiving: 6400, payment: -6400 },
      '60'  => { receiving: 8000, payment: -8000 },
      '70'  => { receiving: 8000, payment: -8000 },
      '80'  => { receiving: 8000, payment: -8000 },
      '90'  => { receiving: 8000, payment: -8000 },
      '100' => { receiving: 8000, payment: -8000 },
      '110' => { receiving: 8000, payment: -8000 }
    },
    '4' => {
      '25'  => { receiving: 6400, payment: -6400 },
      '30'  => { receiving: 8000, payment: -8000 },
      '40'  => { receiving: 8000, payment: -8000 },
      '50'  => { receiving: 8000, payment: -8000 },
      '60'  => { receiving: 8000, payment: -8000 },
      '70'  => { receiving: 8000, payment: -8000 },
      '80'  => { receiving: 8000, payment: -8000 },
      '90'  => { receiving: 8000, payment: -8000 },
      '100' => { receiving: 8000, payment: -8000 },
      '110' => { receiving: 8000, payment: -8000 }
    },
    '5'  => { '*' => { receiving:  8000, payment:  -8000 } },
    '6'  => { '*' => { receiving: 12000, payment: -12000 } },
    '7'  => { '*' => { receiving: 12000, payment: -12000 } },
    '8'  => { '*' => { receiving: 16000, payment: -16000 } },
    '9'  => { '*' => { receiving: 16000, payment: -16000 } },
    '10' => { '*' => { receiving: 16000, payment: -16000 } },
    '11' => { '*' => { receiving: 24000, payment: -24000 } },
    '12' => { '*' => { receiving: 24000, payment: -24000 } },
    '13' => { '*' => { receiving: 32000, payment: -32000 } }
  }

  class << self
    def calculate_point(score_statements, player)
      tsumo = score_statements[:tsumo]
      han = score_statements[:han_total] < 13 ? score_statements[:han_total].to_s : '13'
      fu = han.to_i < 5 ? score_statements[:fu_total].to_s : '*'

      if player.host? && tsumo
        HOST_TSUMO_POINT_TABLE[han][fu]
      elsif player.host? && !tsumo
        HOST_RON_POINT_TABLE[han][fu]
      elsif !player.host? && tsumo
        CHILD_TSUMO_POINT_TABLE[han][fu]
      else
        CHILD_RON_POINT_TABLE[han][fu]
      end
    end
  end
end

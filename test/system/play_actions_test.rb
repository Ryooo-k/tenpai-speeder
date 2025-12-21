# frozen_string_literal: true

require 'application_system_test_case'

class PlayActionsTest < ApplicationSystemTestCase
  include GameTestHelper

  def setup
    login_with_google users(:ryo)
    visit home_path
    find("button[aria-label*='1局戦']").click
    assert_text 'ROUND'

    page.refresh # イベント発火を停止し、ゲームを一時停止状態にする。

    @game = find_game
    @user = @game.user_player
    @shimocha = @game.ais.detect { |ai| ai.relation_from_user == :shimocha }
    @toimen   = @game.ais.detect { |ai| ai.relation_from_user == :toimen }
    @kamicha  = @game.ais.detect { |ai| ai.relation_from_user == :kamicha }

    # AIの choose を手牌からのランダム選択に差し替える
    Player.class_eval do
      def choose
        hands.sample
      end
    end
  end

  def find_game
    path = URI.parse(page.current_url).path
    game_id = path[%r{\A/games/(\d+)/play\z}, 1].to_i
    Game.find(game_id)
  end

  test '上家がチー可能な牌を捨てた時、「チー候補牌」と「スルー」ボタンが表示される' do
    user_hands = set_hands('m23 p1119999 s5 z123', @user, drawn: false)
    manzu_2 = user_hands.first
    manzu_3 = user_hands.second
    set_hands('m111', @kamicha)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @kamicha)

    click_button '▶︎'

    assert_selector 'div[aria-label="副露の選択肢"]'

    chi_form_id = "furo-chi-#{manzu_2.id}-#{manzu_3.id}"
    within "form##{chi_form_id}" do
      assert_selector 'img[alt="manzu2の牌"]'
      assert_selector 'img[alt="manzu3の牌"]'
    end
    assert_text 'スルー'
  end

  test '上家の捨て牌をチーすると、チー牌が左端・横向きで副露に並ぶ' do
    user_hands = set_hands('m23 p1119999 s5 z123', @user, drawn: false)
    manzu_2 = user_hands.first
    manzu_3 = user_hands.second
    set_hands('m111', @kamicha)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @kamicha)

    click_button '▶︎'

    chi_form_id = "furo-chi-#{manzu_2.id}-#{manzu_3.id}"
    find("form##{chi_form_id} button").click

    within "div[data-testid=\"player-melds\"][data-player-id=\"#{@user.id}\"]" do
      meld_tiles = all('img', minimum: 3)
      assert_equal 'manzu1の牌', meld_tiles.first[:alt]
      assert_equal 'true', meld_tiles.first['data-rotated']
      assert_equal [ 'manzu2の牌', 'manzu3の牌' ], meld_tiles[1..2].map { |img| img[:alt] }
    end
  end

  test '上家の捨て牌をチーせずスルーすると、ユーザーが１枚牌を引く' do
    set_hands('m23 p1119999 s5 z123', @user, drawn: false)
    set_hands('m111', @kamicha)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @kamicha)

    hands_selector = "div[data-testid=\"player-hands\"][data-player-id=\"#{@user.id}\"] img"
    assert_selector hands_selector, count: 13

    click_button '▶︎'
    click_button 'スルー'

    assert_selector hands_selector, count: 14
  end

  test '上家がポン可能な牌を捨てた時、「ポン候補牌」と「スルー」ボタンが表示される' do
    user_hands = set_hands('m23 p119999 s55 z123', @user, drawn: false)
    pinzu_1_a = user_hands[2]
    pinzu_1_b = user_hands[3]
    set_hands('p11', @kamicha)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @kamicha)

    click_button '▶︎'

    assert_selector 'div[aria-label="副露の選択肢"]'

    pon_form_id = "furo-pon-#{pinzu_1_a.id}-#{pinzu_1_b.id}"
    within "form##{pon_form_id}" do
      assert_selector 'img[alt="pinzu1の牌"]', count: 2
    end
    assert_text 'スルー'
  end

  test '上家の捨て牌をポンすると、ポン牌が左端・横向きで副露に並ぶ' do
    user_hands = set_hands('m23 p119999 s55 z123', @user, drawn: false)
    pinzu_1_a = user_hands[2]
    pinzu_1_b = user_hands[3]
    set_hands('p11', @kamicha)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @kamicha)

    click_button '▶︎'

    pon_form_id = "furo-pon-#{pinzu_1_a.id}-#{pinzu_1_b.id}"
    find("form##{pon_form_id} button").click

    within "div[data-testid=\"player-melds\"][data-player-id=\"#{@user.id}\"]" do
      meld_tiles = all('img', minimum: 3)
      assert_equal 'pinzu1の牌', meld_tiles.first[:alt]
      assert_equal 'true', meld_tiles.first['data-rotated']
      assert_equal [ 'pinzu1の牌', 'pinzu1の牌' ], meld_tiles[1..2].map { |img| img[:alt] }
    end
  end

  test '上家がカン可能な牌を捨てた時、「カン・ポン候補牌」と「スルー」ボタンが表示される' do
    user_hands = set_hands('m23 p1119999 s5 z123', @user, drawn: false)
    pinzu_1_a = user_hands[2]
    pinzu_1_b = user_hands[3]
    pinzu_1_c = user_hands[4]
    set_hands('p1', @kamicha)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @kamicha)

    click_button '▶︎'

    assert_selector 'div[aria-label="副露の選択肢"]'

    pon_form_id = "furo-pon-#{pinzu_1_a.id}-#{pinzu_1_b.id}"
    within "form##{pon_form_id}" do
      assert_selector 'img[alt="pinzu1の牌"]', count: 2
    end

    daiminkan_form_id = "furo-daiminkan-#{pinzu_1_a.id}-#{pinzu_1_b.id}-#{pinzu_1_c.id}"
    within "form##{daiminkan_form_id}" do
      assert_selector 'img[alt="pinzu1の牌"]', count: 3
    end

    assert_text 'スルー'
  end

  test '上家の捨て牌をカンすると、カン牌が左端・横向きで副露に並ぶ' do
    user_hands = set_hands('m23 p1119999 s5 z123', @user, drawn: false)
    pinzu_1_a = user_hands[2]
    pinzu_1_b = user_hands[3]
    pinzu_1_c = user_hands[4]
    set_hands('p1', @kamicha)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @kamicha)

    click_button '▶︎'

    daiminkan_form_id = "furo-daiminkan-#{pinzu_1_a.id}-#{pinzu_1_b.id}-#{pinzu_1_c.id}"
    find("form##{daiminkan_form_id} button").click

    within "div[data-testid=\"player-melds\"][data-player-id=\"#{@user.id}\"]" do
      meld_tiles = all('img', minimum: 4)
      assert_equal 'pinzu1の牌', meld_tiles.first[:alt]
      assert_equal 'true', meld_tiles.first['data-rotated']
      assert_equal [ 'pinzu1の牌', 'pinzu1の牌', 'pinzu1の牌' ], meld_tiles[1..3].map { |img| img[:alt] }
    end
  end

  test '上家の捨て牌をポンせずスルーすると、ユーザーが１枚牌を引く' do
    user_hands = set_hands('m23 p119999 s55 z123', @user, drawn: false)
    set_hands('p11', @kamicha)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @kamicha)

    hands_selector = "div[data-testid=\"player-hands\"][data-player-id=\"#{@user.id}\"] img"
    assert_selector hands_selector, count: 13

    click_button '▶︎'
    click_button 'スルー'

    assert_selector hands_selector, count: 14
  end

  test '対面がチー可能な牌を捨てた場合、「チー候補牌」と「スルー」ボタンは表示されない' do
    user_hands = set_hands('m23 p1119999 s5 z123', @user, drawn: false)
    set_hands('m111', @toimen)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @toimen)

    click_button '▶︎'

    assert_no_selector 'div[aria-label="副露の選択肢"]'
    assert_no_text 'スルー'
  end

  test '対面がポン可能な牌を捨てた時、「ポン候補牌」と「スルー」ボタンが表示される' do
    user_hands = set_hands('m23 p119999 s55 z123', @user, drawn: false)
    pinzu_1_a = user_hands[2]
    pinzu_1_b = user_hands[3]
    set_hands('p11', @toimen)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @toimen)

    click_button '▶︎'

    assert_selector 'div[aria-label="副露の選択肢"]'

    pon_form_id = "furo-pon-#{pinzu_1_a.id}-#{pinzu_1_b.id}"
    within "form##{pon_form_id}" do
      assert_selector 'img[alt="pinzu1の牌"]', count: 2
    end
    assert_text 'スルー'
  end

  test '対面の捨て牌をポンすると、ポン牌が真ん中・横向きで副露に並ぶ' do
    user_hands = set_hands('m23 p119999 s55 z123', @user, drawn: false)
    pinzu_1_a = user_hands[2]
    pinzu_1_b = user_hands[3]
    set_hands('p11', @toimen)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @toimen)

    click_button '▶︎'

    pon_form_id = "furo-pon-#{pinzu_1_a.id}-#{pinzu_1_b.id}"
    find("form##{pon_form_id} button").click

    within "div[data-testid=\"player-melds\"][data-player-id=\"#{@user.id}\"]" do
      meld_tiles = all('img', minimum: 3)
      assert_equal [ 'pinzu1の牌', 'pinzu1の牌', 'pinzu1の牌' ], meld_tiles.map { |img| img[:alt] }
      assert_equal 'true', meld_tiles[1]['data-rotated']
    end
  end

  test '対面がカン可能な牌を捨てた時、「カン・ポン候補牌」と「スルー」ボタンが表示される' do
    user_hands = set_hands('m23 p1119999 s5 z123', @user, drawn: false)
    pinzu_1_a = user_hands[2]
    pinzu_1_b = user_hands[3]
    pinzu_1_c = user_hands[4]
    set_hands('p1', @toimen)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @toimen)

    click_button '▶︎'

    assert_selector 'div[aria-label="副露の選択肢"]'

    pon_form_id = "furo-pon-#{pinzu_1_a.id}-#{pinzu_1_b.id}"
    within "form##{pon_form_id}" do
      assert_selector 'img[alt="pinzu1の牌"]', count: 2
    end

    daiminkan_form_id = "furo-daiminkan-#{pinzu_1_a.id}-#{pinzu_1_b.id}-#{pinzu_1_c.id}"
    within "form##{daiminkan_form_id}" do
      assert_selector 'img[alt="pinzu1の牌"]', count: 3
    end

    assert_text 'スルー'
  end

  test '対面の捨て牌をカンすると、カン牌の左から２番目の牌が横向きで副露に並ぶ' do
    user_hands = set_hands('m23 p1119999 s5 z123', @user, drawn: false)
    pinzu_1_a = user_hands[2]
    pinzu_1_b = user_hands[3]
    pinzu_1_c = user_hands[4]
    set_hands('p1', @toimen)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @toimen)

    click_button '▶︎'

    daiminkan_form_id = "furo-daiminkan-#{pinzu_1_a.id}-#{pinzu_1_b.id}-#{pinzu_1_c.id}"
    find("form##{daiminkan_form_id} button").click

    within "div[data-testid=\"player-melds\"][data-player-id=\"#{@user.id}\"]" do
      meld_tiles = all('img', minimum: 4)
      assert_selector 'img[alt="pinzu1の牌"]', count: 4
      assert_equal 'true', meld_tiles[1]['data-rotated']
    end
  end

  test '対面の捨て牌をポンせずスルーすると、上家が１枚牌を引く' do
    user_hands = set_hands('m23 p119999 s55 z123', @user, drawn: false)
    set_hands('p11', @toimen)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @toimen)

    hands_selector = "div[data-testid=\"player-hands\"][data-player-id=\"#{@kamicha.id}\"] img"
    assert_selector hands_selector, count: 13

    click_button '▶︎'
    click_button 'スルー'

    assert_selector hands_selector, count: 14
  end

  test '下家がチー可能な牌を捨てた場合、「チー候補牌」と「スルー」ボタンは表示されない' do
    user_hands = set_hands('m23 p1119999 s5 z123', @user, drawn: false)
    set_hands('m111', @shimocha)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @shimocha)

    click_button '▶︎'

    assert_no_selector 'div[aria-label="副露の選択肢"]'
    assert_no_text 'スルー'
  end

  test '下家がポン可能な牌を捨てた時、「ポン候補牌」と「スルー」ボタンが表示される' do
    user_hands = set_hands('m23 p119999 s55 z123', @user, drawn: false)
    pinzu_1_a = user_hands[2]
    pinzu_1_b = user_hands[3]
    set_hands('p11', @shimocha)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @shimocha)

    click_button '▶︎'

    assert_selector 'div[aria-label="副露の選択肢"]'

    pon_form_id = "furo-pon-#{pinzu_1_a.id}-#{pinzu_1_b.id}"
    within "form##{pon_form_id}" do
      assert_selector 'img[alt="pinzu1の牌"]', count: 2
    end
    assert_text 'スルー'
  end

  test '下家の捨て牌をポンすると、ポン牌が右端・横向きで副露に並ぶ' do
    user_hands = set_hands('m23 p119999 s55 z123', @user, drawn: false)
    pinzu_1_a = user_hands[2]
    pinzu_1_b = user_hands[3]
    set_hands('p11', @shimocha)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @shimocha)

    click_button '▶︎'

    pon_form_id = "furo-pon-#{pinzu_1_a.id}-#{pinzu_1_b.id}"
    find("form##{pon_form_id} button").click

    within "div[data-testid=\"player-melds\"][data-player-id=\"#{@user.id}\"]" do
      meld_tiles = all('img', minimum: 3)
      assert_equal [ 'pinzu1の牌', 'pinzu1の牌', 'pinzu1の牌' ], meld_tiles.map { |img| img[:alt] }
      assert_equal 'true', meld_tiles.last['data-rotated']
    end
  end

  test '下家がカン可能な牌を捨てた時、「カン・ポン候補牌」と「スルー」ボタンが表示される' do
    user_hands = set_hands('m23 p1119999 s5 z123', @user, drawn: false)
    pinzu_1_a = user_hands[2]
    pinzu_1_b = user_hands[3]
    pinzu_1_c = user_hands[4]
    set_hands('p1', @shimocha)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @shimocha)

    click_button '▶︎'

    assert_selector 'div[aria-label="副露の選択肢"]'

    pon_form_id = "furo-pon-#{pinzu_1_a.id}-#{pinzu_1_b.id}"
    within "form##{pon_form_id}" do
      assert_selector 'img[alt="pinzu1の牌"]', count: 2
    end

    daiminkan_form_id = "furo-daiminkan-#{pinzu_1_a.id}-#{pinzu_1_b.id}-#{pinzu_1_c.id}"
    within "form##{daiminkan_form_id}" do
      assert_selector 'img[alt="pinzu1の牌"]', count: 3
    end

    assert_text 'スルー'
  end

  test '下家の捨て牌をカンすると、カン牌の右端の牌が横向きで副露に並ぶ' do
    user_hands = set_hands('m23 p1119999 s5 z123', @user, drawn: false)
    pinzu_1_a = user_hands[2]
    pinzu_1_b = user_hands[3]
    pinzu_1_c = user_hands[4]
    set_hands('p1', @shimocha)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @shimocha)

    click_button '▶︎'

    daiminkan_form_id = "furo-daiminkan-#{pinzu_1_a.id}-#{pinzu_1_b.id}-#{pinzu_1_c.id}"
    find("form##{daiminkan_form_id} button").click

    within "div[data-testid=\"player-melds\"][data-player-id=\"#{@user.id}\"]" do
      meld_tiles = all('img', minimum: 4)
      assert_selector 'img[alt="pinzu1の牌"]', count: 4
      assert_equal 'true', meld_tiles.last['data-rotated']
    end
  end

  test '下家の捨て牌をポンせずスルーすると、対面が１枚牌を引く' do
    user_hands = set_hands('m23 p119999 s55 z123', @user, drawn: false)
    set_hands('p11', @shimocha)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @shimocha)

    hands_selector = "div[data-testid=\"player-hands\"][data-player-id=\"#{@toimen.id}\"] img"
    assert_selector hands_selector, count: 13

    click_button '▶︎'
    click_button 'スルー'

    assert_selector hands_selector, count: 14
  end

  test 'ユーザーがリーチ可能な時、「リーチ」と「パス」のボタンが表示される' do
    user_hands = set_hands('m123456789 p23 s55', @user)

    @game.current_step.update!(next_event: 'draw')
    set_player_turn(@game, @user)
    set_draw_tile('s9', @game) # ドロー時にツモ和了とならないようにする

    click_button '▶︎'

    assert_text 'リーチ'
    assert_text 'パス'
  end

  test 'ユーザーがリーチ宣言後、リーチ可能な打牌候補しか選択できなくなる' do
    set_hands('m123456789 p23 s55', @user)

    @game.current_step.update!(next_event: 'draw')
    set_player_turn(@game, @user)
    set_draw_tile('s9', @game) # ドロー時にツモ和了とならないようにする

    click_button '▶︎'
    click_button 'リーチ'

    @game.reload
    radio_selector = 'input[type="radio"][name="chosen_hand_id"]'
    assert_selector radio_selector, count: 1

    souzu9_hand = @user.hands.find { |hand| hand.suit == 'souzu' && hand.number == 9 }
    radio_values = all(radio_selector).map { |input| input.value.to_i }
    assert_equal [ souzu9_hand.id ], radio_values
  end

  test 'ユーザーがリーチをパス後、手牌の全てが打牌選択可能となる' do
    set_hands('m123456789 p23 s55', @user)

    @game.current_step.update!(next_event: 'draw')
    set_player_turn(@game, @user)
    set_draw_tile('s9', @game) # ドロー時にツモ和了とならないようにする

    click_button '▶︎'
    click_button 'パス'

    @game.reload
    radio_selector = 'input[type="radio"][name="chosen_hand_id"]'
    assert_selector radio_selector, count: @user.hands.count
  end

  test 'ユーザーがロン可能な時、「ロン」と「スルー」のボタンが表示される' do
    user_hands = set_hands('m123456789 p23 s55', @user)
    set_hands('p1', @shimocha)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @shimocha)

    click_button '▶︎'

    assert_text 'ロン'
    assert_text 'スルー'
  end

  test 'ユーザーがロンした時、対局結果が表示される' do
    user_hands = set_hands('m123456789 p23 s55', @user)
    set_hands('p1', @shimocha)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @shimocha)

    click_button '▶︎'
    click_button 'ロン'

    assert_text '対局結果'
  end

  test 'ユーザーがロンをスルーした時、次のプレイヤーが１枚牌を引く' do
    user_hands = set_hands('m123456789 p23 s55', @user)
    set_hands('p1', @shimocha)

    @game.current_step.update!(next_event: 'choose')
    set_player_turn(@game, @shimocha)

    hands_selector = "div[data-testid=\"player-hands\"][data-player-id=\"#{@toimen.id}\"] img"
    assert_selector hands_selector, count: 13

    click_button '▶︎'
    click_button 'スルー'

    hands_selector = "div[data-testid=\"player-hands\"][data-player-id=\"#{@toimen.id}\"] img"
    assert_selector hands_selector, count: 14
  end

  test 'ユーザーがカカンできる時、「カカン候補牌」と「パス」ボタンが表示される' do
    user_hands = set_hands('m123456 p23 s19', @user)
    set_melds('z111=', @user)

    @game.current_step.update!(next_event: 'draw')
    set_player_turn(@game, @user)
    set_draw_tile('z1', @game) # カカン可能な牌をセット

    click_button '▶︎'

    assert_selector 'div[aria-label="カンの選択肢"]'
    assert_selector 'form[data-testid="kakan_candidate"]', count: 1
    within 'form[data-testid="kakan_candidate"]' do
      assert_selector 'img[alt="zihai1の牌"]', minimum: 4
    end
    assert_text 'パス'
  end

  test 'ユーザーがカカンした時、カカン牌は横向きになる' do
    set_hands('m123456 p23 s19', @user)
    set_melds('z111=', @user)

    @game.current_step.update!(next_event: 'draw')
    set_player_turn(@game, @user)
    set_draw_tile('z1', @game) # カカン可能な牌をセット

    click_button '▶︎'

    within 'form[data-testid="kakan_candidate"]' do
      click_button
    end

    within "div[data-testid=\"player-melds\"][data-player-id=\"#{@user.id}\"]" do
      kakan_tile = all('img[data-kind="kakan"]', minimum: 1).first
      assert_selector 'img[alt="zihai1の牌"][data-kind="kakan"]', count: 1
      assert_selector 'img[alt="zihai1の牌"][data-kind="pon"]', count: 3
      assert_equal 'true', kakan_tile['data-rotated']
      assert_equal 'true', kakan_tile['data-overlay']
    end
  end
end

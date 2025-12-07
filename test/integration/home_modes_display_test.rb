# frozen_string_literal: true

require 'test_helper'

class HomeModesDisplayTest < ActionDispatch::IntegrationTest
  test 'ゲームモードがパターンごとにまとめて表示される' do
    get home_path
    assert_response :success

    assert_select "section[data-mode-type='final_round']" do
      assert_select 'h2', text: 'オーラス特化'
      assert_select 'li h2', text: '1局戦'
      assert_select 'li h2', text: '着順UP練習'
      assert_select 'li h2', text: '東風戦', count: 0
      assert_select 'li h2', text: '東南戦', count: 0
    end

    assert_select "section[data-mode-type='match']" do
      assert_select 'h2', text: '対局形式'
      assert_select 'li h2', text: '東風戦'
      assert_select 'li h2', text: '東南戦'
      assert_select 'li h2', text: '1局戦', count: 0
      assert_select 'li h2', text: '着順UP練習', count: 0
    end
  end
end

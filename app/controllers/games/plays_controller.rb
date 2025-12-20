# frozen_string_literal: true

class Games::PlaysController < ApplicationController
  include Games::PlaySupport

  before_action :set_game
  before_action :set_instance_variable, only: :show

  def show
  end

  def command
    game_flow = GameFlow.new(@game)
    payloads = game_flow.run(game_flow_params)

    respond_to do |format|
      format.turbo_stream { render_play_update(payloads) }
      format.html { redirect_to game_play_path(@game), flash: payloads }
    end

  rescue GameFlow::SaveError => e
    Rails.logger.error("[GameFlow] SaveError: #{e.message} (#{e.cause&.class})")
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = 'ゲームの保存に失敗しました。時間をおいて再度お試しください。'
        render :error
      end
      format.html { redirect_to game_play_path(@game), alert: 'ゲームの保存に失敗しました。時間をおいて再度お試しください。' }
    end
  rescue GameFlow::UnknownEvent => e
    Rails.logger.warn("[GameFlow] UnknownEvent: #{e.message} (game_id=#{@game.id}, event=#{params[:event]})")
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = e.message
        render :error
      end
      format.html { redirect_to game_play_path(@game), alert: e.message }
    end
  end

  private

    def game_flow_params
      event = params.expect(:event)
      flow_requests = { event: }

      case event.to_sym
      when :confirm_tsumo
        tsumo = params.expect(:tsumo)
        flow_requests[:tsumo] = ActiveModel::Type::Boolean.new.cast(tsumo)
      when :confirm_riichi
        riichi = params.expect(:riichi)
        flow_requests[:riichi] = ActiveModel::Type::Boolean.new.cast(riichi)
      when :choose_riichi
        riichi_candidate_ids = params.expect(riichi_candidate_ids: [])
        flow_requests[:riichi_candidate_ids] = riichi_candidate_ids.map(&:to_i)
      when :discard
        chosen_hand_id = params.expect(:chosen_hand_id)
        flow_requests[:chosen_hand_id] = chosen_hand_id.to_i
      when :confirm_ron
        discarded_tile_id, kakan, ron_player_ids = params.expect(:discarded_tile_id, :kakan, ron_player_ids: [])
        flow_requests[:discarded_tile_id] = discarded_tile_id
        flow_requests[:kakan] = ActiveModel::Type::Boolean.new.cast(kakan)
        flow_requests[:ron_player_ids] = ron_player_ids.reject(&:blank?).map(&:to_i)
      when :confirm_furo
        furo = params.expect(:furo)
        flow_requests[:furo] = ActiveModel::Type::Boolean.new.cast(furo)

        if flow_requests[:furo]
          discarded_tile_id, furo_type, furo_ids = params.expect(:discarded_tile_id, :furo_type, furo_ids: [])
          flow_requests[:discarded_tile_id] = discarded_tile_id.to_i
          flow_requests[:furo_type] = furo_type.to_s
          flow_requests[:furo_ids] = furo_ids.map(&:to_i)
        end
      when :confirm_kan
        kan = params.expect(:kan)
        flow_requests[:kan] = ActiveModel::Type::Boolean.new.cast(kan)

        if flow_requests[:kan]
          kan_type, kan_ids = params.expect(:kan_type, kan_ids: [])
          flow_requests[:kan_type] = kan_type.to_s
          flow_requests[:kan_ids] = kan_ids.map(&:to_i)
        end
      when :result
        ryukyoku = params.expect(:ryukyoku)
        flow_requests[:ryukyoku] = ActiveModel::Type::Boolean.new.cast(ryukyoku)
      end

      flow_requests
    end
end

# frozen_string_literal: true

module ApplicationHelper
  def turbo_stream_flash
    turbo_stream.update 'flash', partial: 'application/flash'
  end

  def current_path
    request&.path
  end
end

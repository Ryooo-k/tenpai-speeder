# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_forgery_protection only: [ :create, :guest ]

  def new
  end

  def create
    auth = request.env['omniauth.auth']

    user = User.find_or_create_by!(provider: auth[:provider], uid: auth[:uid]) do |new_user|
      new_user.name = auth[:info][:name]
    end

    reset_session
    session[:user_id] = user.id
    redirect_to home_path, notice: 'ログインしました'

  rescue ActiveRecord::RecordInvalid => e
    redirect_to root_path, alert: 'ユーザー認証に失敗しました'
  end

  def destroy
    reset_session
    redirect_to root_path, notice: 'ログアウトしました'
  end

  def guest
    user = User.new(name: "guest-#{SecureRandom.hex(3)}")

    if user.save
      reset_session
      session[:user_id] = user.id
      redirect_to home_path, notice: "ログインしました(#{user.name})"
    else
      redirect_to root_path, alert: 'ユーザー認証に失敗しました'
    end
  end
end

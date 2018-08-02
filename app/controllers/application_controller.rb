class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :check_user
  
  def check_user
    @session_str = params[:session_str] || cookies[:eztag]
    if params[:session_str].present?
      @current_user = User.where("session_str = ?", @session_str).first
      @ask_new_session = true
    elsif current_user.present?
      @current_user = current_user
    else
      @current_user = current_user || User.where("session_str = ?", @session_str).first unless @session_str.nil?
    end

    if @current_user.blank? && @session_str.present?
      @current_user = nil
      cookies.delete :eztag
      @ask_new_session = true
    end

    if @current_user.present? && @current_user.session_str.present?
      cookies[:eztag] = {
        value: @current_user.session_str,
        expires: 10.year.from_now
      }
      sign_in(@current_user)
    end
  end
end

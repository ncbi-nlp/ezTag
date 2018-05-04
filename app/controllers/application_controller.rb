class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :check_user
  
  def check_user
    @session_str = params[:session_str] || cookies[:eztag]
    @current_user = User.where("session_str = ?", @session_str).first unless @session_str.nil?
    logger.debug "CurrentUser #{@current_user} Session Str #{@session_str}"
    if @current_user.blank? && @session_str.present?
      @current_user = nil
      cookies.delete :eztag
      @ask_new_session = true
    end

    unless @ask_new_session
      if @current_user.nil?
        @current_user = User.new_user
      end
      cookies[:eztag] = {
        value: @current_user.session_str,
        expires: 10.year.from_now
      }
      @current_user.ip = request.remote_ip
      @current_user.save
    end
  end
end

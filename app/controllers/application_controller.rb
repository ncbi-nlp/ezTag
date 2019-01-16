class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, unless: -> { request.format.json? || request.format.xml? }
  before_action :check_user
  
  def check_user
    @params_key = params[:key] || request.headers['x-api-key']
    if (request.format.json? || request.format.xml?) && (!user_signed_in? || @params_key.present?)
      key = ApiKey.where("`key`=?", @params_key).first if @params_key.present?
      if key.present?
        key.access_count += 1
        key.last_access_ip = request.remote_ip
        key.last_access_at = Time.now.utc
        key.save
        @current_user = key.user
        sign_in(key.user)
      else
        respond_to do |format|
          format.json { render :json => {error: 'Access Denied'}, :status => 401 }
          format.xml { render :json => {error: 'Access Denied'}, :status => 401 }
        end
        return false
      end
    else
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


  def breadcrumb_for_collections(collection = nil)
    if collection.present?
      title = "Collections"
      if @current_user.super_admin?
        title = title + " of #{collection.user.email_or_id}"
      end
      if @current_user.id == collection.user_id
        semantic_breadcrumb title, collections_path
      else
        semantic_breadcrumb title, user_collections_path(collection.user)
      end
    end
  end
end

class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:index, :show, :new, :edit, :create, :update]

  before_action :set_user, only: [:show, :edit, :update, :destroy]
  # GET /users
  # GET /users.json
  def index
    unless @current_user.super_admin?
      return redirect_to "/"
    end
    @users = User.page params[:page]
  end

  # GET /users/1
  # GET /users/1.json
  def show
    # semantic_breadcrumb :Account
    if @current_user.session_str.present?
      @url = "#{request.protocol}#{request.host_with_port}/sessions/" + @current_user.session_str
    end
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
    unless @user.valid_email?
      @user.email = ""
    end
  end

  def generate
    if verify_recaptcha
      @current_user = User.new_user
      @current_user.save
      logger.debug(@current_user.errors.inspect)
      sign_in(@current_user)
      redirect_to '/', notice: 'Session was successfully created.'
    else
      redirect_to new_user_session_url, alert: 'Please check reCAPTCHA'
    end 
  end

  def sessions
    if @ask_new_session && @current_user.present?
      if @current_user.session_str.present?
        @url = "#{request.protocol}#{request.host_with_port}/sessions/" + @current_user.session_str
      end
      render :show
    else
      redirect_to "/", alert: "Session is not exist: '#{params[:session_str]}'"
    end
  end

  def sendmail
    path = "/sessions/#{@current_user.session_str}"
    UserMailer.session_email(params[:email], @current_user, request.base_url + path).deliver_later
    redirect_to path, notice: "Email was successfully sent."
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)
    return
    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:email, :password)
    end
end

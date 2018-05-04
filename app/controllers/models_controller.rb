class ModelsController < ApplicationController
  before_action :set_model, only: [:show, :edit, :update, :destroy]
  before_action :set_top_menu
  semantic_breadcrumb :index, :lexicon_groups_path

  # GET /models
  # GET /models.json
  def index
    @models = @current_user.models.page(params[:page])
  end

  # GET /models/1
  # GET /models/1.json
  def show
  end

  # GET /models/new
  def new
    @model = Model.new
  end

  # GET /models/1/edit
  def edit
  end

  # POST /models
  # POST /models.json
  def create
    @model = @current_user.models.new(model_params)

    respond_to do |format|
      if @model.save
        format.html { redirect_to @model, notice: 'The model was successfully created.' }
        format.json { render :show, status: :created, location: @model }
      else
        format.html { render :new }
        format.json { render json: @model.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /models/1
  # PATCH/PUT /models/1.json
  def update
    respond_to do |format|
      if @model.update(model_params)
        format.html { redirect_to @model, notice: 'The model was successfully updated.' }
        format.json { render :show, status: :ok, location: @model }
      else
        format.html { render :edit }
        format.json { render json: @model.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /models/1
  # DELETE /models/1.json
  def destroy
    @model.destroy
    respond_to do |format|
      format.html { redirect_back fallback_location: models_url, notice: 'The model was successfully removed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_model
      @model = Model.find(params[:id])
    end
    def set_top_menu
      @top_menu = 'models'
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def model_params
      params.require(:model).permit(:url, :user_id, :name)
    end
end

class LexiconGroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_lexicon_group, only: [:show, :edit, :update, :destroy]
  before_action :set_top_menu
  semantic_breadcrumb :index, :lexicon_groups_path

  # GET /lexicon_groups
  # GET /lexicon_groups.json
  def index
    @lexicon_groups = @current_user.lexicon_groups.page params[:page]
  end

  # GET /lexicon_groups/1
  # GET /lexicon_groups/1.json
  def show
  end

  # GET /lexicon_groups/new
  def new
    @lexicon_group = LexiconGroup.new
  end

  # GET /lexicon_groups/1/edit
  def edit
  end

  def load_samples
    LexiconGroup.load_samples(@current_user)
    respond_to do |format|
      format.html { redirect_to lexicon_groups_url, notice: 'The lexicon was successfully created.' }
    end
  end

  # POST /lexicon_groups
  # POST /lexicon_groups.json
  def create
    @lexicon_group = @current_user.lexicon_groups.new(lexicon_group_params)

    respond_to do |format|
      if @lexicon_group.save
        format.html { redirect_to lexicon_groups_path, notice: 'The lexicon was successfully created.' }
        format.json { render :show, status: :created, location: @lexicon_group }
      else
        format.html { render :new }
        format.json { render json: @lexicon_group.errors, status: :unprocessable_entity }
      end
    end
  end

# PATCH/PUT /lexicon_groups/1
  # PATCH/PUT /lexicon_groups/1.json
  def update
    respond_to do |format|
      if @lexicon_group.update(lexicon_group_params)
        format.html { redirect_back fallback_location: lexicon_groups_url, notice: 'The lexicon was successfully updated.' }
        format.json { render :show, status: :ok, location: @lexicon_group }
      else
        format.html { render :edit }
        format.json { render json: @lexicon_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lexicon_groups/1
  # DELETE /lexicon_groups/1.json
  def destroy
    @lexicon_group.destroy
    respond_to do |format|
      format.html { redirect_back fallback_location: lexicon_groups_url, notice: 'The lexicon was successfully removed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_lexicon_group
      @lexicon_group = LexiconGroup.find(params[:id])
    end
    def set_top_menu
      @top_menu = 'lexicons'
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def lexicon_group_params
      params.require(:lexicon_group).permit(:name, :user_id)
    end
end

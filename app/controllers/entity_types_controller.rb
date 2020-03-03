class EntityTypesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_entity_type, only: [:show, :edit, :update, :destroy]
  before_action :set_collection, only: [:new, :create, :index, :import_default_color]

  # GET /entity_types
  # GET /entity_types.json
  def index
    breadcrumb_for_collections(@collection)
    semantic_breadcrumb @collection.name, @collection
    semantic_breadcrumb "Entity Types"
    @entity_types = @collection.entity_types
  end

  # GET /entity_types/1
  # GET /entity_types/1.json
  def show
  end

  # GET /entity_types/new
  def new
    breadcrumb_for_collections(@collection)
    semantic_breadcrumb @collection.name, @collection
    semantic_breadcrumb "Entity Types", collection_entity_types_path(@collection)
    semantic_breadcrumb "new"
    @entity_type = EntityType.new
    @entity_type.color = EntityType.random_color
  end

  # GET /entity_types/1/edit
  def edit
    @collection = @entity_type.collection
    breadcrumb_for_collections(@collection)
    semantic_breadcrumb @collection.name, @collection
    semantic_breadcrumb "Entity Types", collection_entity_types_path(@collection)
    semantic_breadcrumb "edit"
  end

  # POST /entity_types
  # POST /entity_types.json
  def create
    @entity_type = EntityType.new(entity_type_params)
    @entity_type.collection_id = @collection.id
    respond_to do |format|
      if @entity_type.save
        format.html { redirect_to collection_entity_types_path(@collection), notice: 'The entity type was successfully created.' }
        format.json { render :show, status: :created, location: @entity_type }
      else
        format.html { render :new }
        format.json { render json: @entity_type.errors, status: :unprocessable_entity }
      end
    end
  end

  def import_default_color
    EntityType.transaction do 
      EntityType::DEFAULT_COLORMAP.each do |k, c|
        found = false
        @collection.entity_types.each do |e|
          name = e.name.strip.downcase
          logger.debug("CHECK NAME #{name} == #{k}")
          if name == k
            e.color = c
            e.name = EntityType::DEFAULT_NAMEMAP[k]
            e.save
            found = true
          end
        end
        if !found
          @collection.entity_types.create!({name: EntityType::DEFAULT_NAMEMAP[k], color: c})
        end
      end
    end

    respond_to do |format|
      format.html { redirect_to collection_entity_types_path(@collection), notice: 'The entity type was successfully imported.' }
    end
  end


  # PATCH/PUT /entity_types/1
  # PATCH/PUT /entity_types/1.json
  def update
    @collection = @entity_type.collection
    respond_to do |format|
      if @entity_type.update(entity_type_params)
        format.html { redirect_to collection_entity_types_path(@collection), notice: 'The entity type was successfully updated.' }
        format.json { render :show, status: :ok, location: @entity_type }
      else
        format.html { render :edit }
        format.json { render json: @entity_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /entity_types/1
  # DELETE /entity_types/1.json
  def destroy
    @collection = @entity_type.collection
    @entity_type.destroy
    respond_to do |format|
      format.html { redirect_to collection_entity_types_path(@collection), notice: 'The entity type was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_entity_type
      @entity_type = EntityType.find(params[:id])
    end

    def set_collection
      @collection = Collection.find(params[:collection_id])
      unless @collection.available?(@current_user)
        respond_to do |format|
          format.html { redirect_back fallback_location: collections_path, error: "Cannot access the project"}
          format.json { render json: {msg: 'Cannot access project'}, status: 401 }
        end    
        return false
      end
    end


    # Never trust parameters from the scary internet, only allow the white list through.
    def entity_type_params
      params.require(:entity_type).permit(:collection_id, :name, :color)
    end
end

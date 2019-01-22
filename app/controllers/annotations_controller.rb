class AnnotationsController < ApplicationController
  before_action :set_document

  # GET /annotations
  # GET /annotations.json
  def index
  end

  # GET /annotations/1
  # GET /annotations/1.json
  def show
    @entity_types = EntityType.where(collection_id: @document.collection_id)
    @document.adjust_offset(true)
  end

  # GET /annotations/new
  def new
  end

  # GET /annotations/1/edit
  def edit
  end

  # POST /annotations
  # POST /annotations.json
  def create
    @text = (params[:text] || "").strip
    @offset = (params[:offset] || "-1").to_i
    @concept = params[:concept] || ""
    @type = params[:type] || ""
    @note = params[:note] || ""
    @ret = @document.add_annotation(@current_user.email, @text, @offset, @type, @concept, @note)
    @entity_types = EntityType.where(collection_id: @document.collection_id)

    respond_to do |format|
      format.html { redirect_to @annotation, notice: 'The annotation was successfully created.' }
      format.json { render :show, status: :ok, location: @annotation }
    end
  end

  # PATCH/PUT /annotations/1
  # PATCH/PUT /annotations/1.json
  def update
    @concept = params[:concept] || ""
    @type = params[:type] || ""
    @note = params[:note] || ""
    @no_update_note = params[:no_update_note] 
    @concept.strip!
    @type.strip!
    if params[:mode] == "true" || params[:mode] == "1" || params[:mode] == "concept"
      logger.debug("update_concept")
      @document.update_concept(@current_user.email, params[:id], @type, @concept, @note, @no_update_note)
    else
      logger.debug("update_mention")
      @document.update_mention(@current_user.email, params[:id], @type, @concept, @note, @no_update_note)
    end
    if params[:annotate_all] == "all"
      @text = (params[:text] || "").strip
      @case_sensitive = (params[:case_sensitive] == "y")
      @whole_word = (params[:whole_word] == "y")
      @document.annotate_all_by_text(@current_user.email, @text, @type, @concept, @case_sensitive, @whole_word, @note)
    end
    @entity_types = EntityType.where(collection_id: @document.collection_id)
    respond_to do |format|
      if true
        format.html { redirect_to @annotation, notice: 'The annotation was successfully updated.' }
        format.json { render :show, status: :ok, location: @annotation }
      else
        format.html { render :edit }
        format.json { render json: @annotation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /annotations/1
  # DELETE /annotations/1.json
  def destroy
    @mode = params[:deleteMode]
    if @mode == "batch"
      ids = []
      offsets = []
      params[:offsets].each do |k, v|
        id = v["id"]
        offset = v["offset"].to_i
        ids << id
        offsets << {id: id, offset: offset}
      end 
      @document.delete_annotation(@mode, ids, offsets, params[:type], params[:concept])
    else
      @id = params[:id]
      @offset = (params[:offset] || "-1").to_i
      @document.delete_annotation(@mode, @id, @offset, params[:type], params[:concept])
    end
    @entity_types = EntityType.where(collection_id: @document.collection_id)
    # @annotation.destroy
    respond_to do |format|
      format.html { redirect_to @document, notice: 'The annotation was successfully deleted.' }
      format.json { render :show, status: :ok, location: @annotation }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_document
      @document = Document.find(params[:document_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def annotation_params
      params.require(:annotation).permit(:document_id, :entity_type, :concept_id)
    end
end

class DocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_collection, only: [:create, :new, :index]
  before_action :set_document, only: [:show, :edit, :partial, :update, 
                  :destroy, :verify, :delete_all_annotations, 
                  :reorder,
                  :done, :curatable]
  before_action :set_top_menu
  helper_method :sort_column, :sort_direction

  # GET /documents
  # GET /documents.json
  def index
    breadcrumb_for_collections(@collection)
    semantic_breadcrumb @collection.name
    @documents = @collection.documents
    @documents = @documents.where("did = ?", params[:did]) if params[:did].present?
    
    if params[:term].present?
      @documents = @documents.where("did like ? or title like ?", "%#{params[:term]}%", "%#{params[:term]}%")
    end

    if sort_column == "default"
      @documents = @documents.order("batch_id DESC, batch_no ASC, id DESC")
    else    
      @documents = @documents.order(sort_column + " " + sort_direction)
    end
    @documents = @documents.order("batch_id DESC, batch_no ASC, id DESC")
    unless request.format.json?
      # @documents = @documents.order("batch_id DESC, batch_no ASC, id DESC").page(params[:page])
      @documents = @documents.page(params[:page])
    end
  end

  # GET /documents/1
  # GET /documents/1.json
  def show
    @collection = @document.collection
    @document.adjust_offset(true)
    unless @collection.available?(@current_user)
      return redirect_to collections_path, error: "Cannot access the document"
    end
    respond_to do |format|
      format.html
      format.json
      format.xml {render xml: @document.xml}
    end
  end

  def partial
    @document.adjust_offset(true)
    unless @document.collection.available?(@current_user)
      return render text: ""
    end
    respond_to do |format|
      format.html {render layout: false}
      format.json
      format.xml {render xml: @document.xml}
    end
  end

  # GET /documents/new
  def new
    @document = Document.new
    breadcrumb_for_collections(@collection)
    semantic_breadcrumb @collection.name, @collection
    semantic_breadcrumb "Add Documents"
  end

  # GET /documents/1/edit
  def edit
  end

  def check
    pmid = params[:id]
    if pmid.start_with?('PMC')
      url = "https://www.ncbi.nlm.nih.gov/pmc/articles/" + pmid
    else
      url = "https://www.ncbi.nlm.nih.gov/pubmed/" + pmid
    end
    response = HTTParty.get(url)
    logger.debug(response.code)

    if response.code == 404
      message = "not exist ID"
    else 
      message = "cannot retrieve (not open-accessible? or internal error?). Please try again or check <a href='" + url + "'>" + url + "</a>"
    end
    respond_to do |format|
      format.json { render json: {message: message} }
    end    
  end

  def verify
    @collection = @document.collection
    render json: @document.verify
  end

  def delete_all_annotations
    @collection = @document.collection
    unless @collection.available?(@current_user)
      respond_to do |format|
        format.html { redirect_to collections_path, error: "Cannot access the document"}
        format.json { render json: {}, status: 401 }
      end    
      return
    end
    ret = @document.delete_all_annotations
    @collection.update_annotation_count
    respond_to do |format|
      format.html { redirect_to @collection, notice: 'Annotations were successfully deleted.'}
      format.json { render json: {ok: true} }
    end    
  end

  def done
    @collection = @document.collection
    unless @collection.available?(@current_user)
      render json: {error: "You're not authorized"}, status: 401
      return
    end
    @document.done = params[:value]
    @document.save!
    render json: @document
  end

  def curatable
    @collection = @document.collection
    unless @collection.available?(@current_user)
      render json: {error: "You're not authorized"}, status: 401
      return
    end
    Document.transaction do 
      @document.bioc_doc.infons["curatable"] = params[:value]
      @document.save_xml(@document.bioc)
    end
    render json: @document
  end

  # POST /documents
  # POST /documents.json
  def create
    batch_id = params[:batch_id]
    if batch_id.blank?
      ub = UploadBatch.create!
      batch_id = ub.id
    end

    unless @collection.available?(@current_user)
      if request.format.json?
        render json: {error: "You're not authorized"}, status: 401
        return
      else
        redirect_to "/", error: "Cannot access the document"
        return
      end
    end
    
    logger.debug(params.inspect)
    if params[:file].present?
      error, dids = @collection.upload_from_file(params[:file], batch_id, params[:replace])
    elsif params[:pmid].present?
      error, dids = @collection.upload_from_pmids(params[:pmid], batch_id, params[:id_map])
    end
    logger.debug("RET === #{error.inspect}")
    
    respond_to do |format|
      if error.nil?
        format.html { redirect_to @collection, notice: 'Document was successfully created.' }
        format.json {  render json: {ok: true, ids: dids, batch_id: batch_id}, status: :created }
      else
        format.html { redirect_to @collection, alert: 'Failed to create document (PMID: does not exist)' }
        format.json { render json: {error: error}, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /documents/1
  # PATCH/PUT /documents/1.json
  def update
    @collection = @document.collection
    respond_to do |format|
      if @document.update(document_params)
        format.html { redirect_back fallback_location: collection_documents_path(@collection), notice: 'The document was successfully updated.' }
        format.json { render :show, status: :ok, location: @document }
      else
        format.html { render :edit }
        format.json { render json: {error: @document.errors}, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /documents/1
  # DELETE /documents/1.json
  def destroy
    @collection = @document.collection
    @document.destroy
    @collection.update_annotation_count
    respond_to do |format|
      format.html { redirect_back fallback_location: collection_documents_path(@collection), notice: 'The document was successfully removed.' }
      format.json { head :no_content }
    end
  end

  def reorder
    @collection = @document.collection
    src = @document.order_no
    if params[:dest] == "last"
      dest = @collection.documents.size
    else
      dest = params[:dest].to_i
    end
    Document.transaction do 
      if dest > @document.order_no
        @collection.documents.where("order_no > ? and order_no <= ?", src, dest).update_all("order_no = order_no - 1")
        @document.order_no = dest
        @document.save!
      elsif dest < @document.order_no
        @collection.documents.where("order_no >= ? and order_no < ?", dest, src).update_all("order_no = order_no + 1")
        @document.order_no = dest
        @document.save!
      end
    end
    respond_to do |format|
      format.html { redirect_back fallback_location: collection_documents_path(@collection), notice: 'The document was successfully reordered.' }
      format.json { head :no_content }
    end      
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_document
      @document = Document.find(params[:id])
      unless @document.collection.available?(@current_user)
        respond_to do |format|
          format.html { redirect_back fallback_location: collections_path, error: "Cannot access the document"}
          format.json { render json: {msg: 'Cannot access document'}, status: 401 }
        end    
        return false
      end
    end
    def set_collection
      @collection = Collection.find(params[:collection_id])
      unless @collection.available?(@current_user)
        respond_to do |format|
          format.html { redirect_back fallback_location: collections_path, error: "Cannot access the document"}
          format.json { render json: {msg: 'Cannot access document'}, status: 401 }
        end    
        return false
      end
    end
    def set_top_menu
      @top_menu = 'collections'
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def document_params
      params.require(:document).permit(:collection_id, :did, :user_updated_at, :tool_updated_at, :annotations_count)
    end

    def sort_column
      Document.column_names.include?(params[:sort]) ? params[:sort] : "default"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
    end
end

require 'zip'

class CollectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_collection, only: [:show, :edit, :update, :destroy, :download, :empty, :delete_all_annotations, :done_all]
  before_action :set_top_menu
  semantic_breadcrumb :index, :collections_path
  # GET /collections
  # GET /collections.json
  def index
    logger.debug("CURRENT_USER = #{current_user}")
    logger.debug("@CURRENT_USER = #{@current_user}")

    @collections = @current_user.collections.all
  end

  def partial
    @collections = @current_user.collections.all
    respond_to do |format|
      format.html {render layout: false}
      format.json
      format.xml {render xml: @document.xml}
    end
  end

  # GET /collections/1
  # GET /collections/1.json
  def show
    respond_to do |format|
      format.html {
        redirect_to collection_documents_path(@collection)
      }
      format.json
    end
  end

  def load_samples
    Collection.load_samples(@current_user)
    respond_to do |format|
      format.html { redirect_to collections_url, notice: 'The sample collections were successfully created.' }
    end
  end
  # GET /collections/new
  def new
    @collection = Collection.new
  end

  # GET /collections/1/edit
  def edit
  end

  # POST /collections
  # POST /collections.json
  def create
    @collection = @current_user.collections.new(collection_params)

    respond_to do |format|
      if @collection.save
        format.html { redirect_to collection_documents_path(@collection), notice: 'The collection was successfully created.' }
        format.json { render :show, status: :created, location: @collection }
      else
        format.html { render :new }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  def download
    filename = "#{@collection.id}-#{Time.now.to_i}.zip"
    temp_file = Tempfile.new(filename)
    names = []
    begin
      #This is the tricky part
      #Initialize the temp file as a zip file
      Zip::OutputStream.open(temp_file) { |zos| }
     
      #Add files to the zip file as usual
      Zip::File.open(temp_file.path, Zip::File::CREATE) do |zip|
        @collection.documents.each do |d|
          name = "#{d.did || d.id}.xml"
          if names.include?(name)
            name = "#{d.did}_#{d.id}.xml"
          end
          zip.get_output_stream(name) { |os| os.write d.xml }
          names << name
        end
      end
      zip_data = File.read(temp_file.path)
 
      #Send the data to the browser as an attachment
      #We do not send the file directly because it will
      #get deleted before rails actually starts sending it
      send_data(zip_data, filename: "c#{@collection.id}_#{@collection.name}.zip", type: 'application/zip')
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  # PATCH/PUT /collections/1
  # PATCH/PUT /collections/1.json
  def update
    respond_to do |format|
      if @collection.update(collection_params)
        format.html { redirect_to collection_documents_path(@collection), notice: 'The collection was successfully updated.' }
        format.json { render :show, status: :ok, location: @collection }
      else
        format.html { render :edit }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /collections/1
  # DELETE /collections/1.json
  def destroy
    @collection.destroy
    respond_to do |format|
      format.html { redirect_to collections_url, notice: 'The collection was successfully removed.' }
      format.json { head :no_content }
    end
  end

  def empty
    @collection.documents.destroy_all
    @collection.update_annotation_count
    respond_to do |format|
      format.html { redirect_to collection_documents_path(@collection), notice: 'All documents were successfully deleted.' }
      format.json { head :no_content }
    end
  end

  def delete_all_annotations
    logger.debug(params.inspect)
    Collection.transaction do 
      @collection.documents.each {|d| d.delete_all_annotations}
      @collection.update_annotation_count
    end
    
    if params[:from] == "list"
      return_path = collections_url
    else
      return_path = @collection
    end
    respond_to do |format|
      format.html { redirect_to return_path, notice: 'Annotations were successfully deleted.'}
      format.json { render json: {ok: true} }
    end    
  end

  def done_all
    Document.transaction do 
      Document.where('collection_id = ?', @collection.id).update_all(done: params[:value].to_s == 'true')
    end
    redirect_to @collection, notice: 'Successfully changed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_collection
      @collection = @current_user.collections.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def collection_params
      params.require(:collection).permit(:name, :note, :source, :cdate, :key)
    end

    def set_top_menu
      @top_menu = 'collections'
    end
end

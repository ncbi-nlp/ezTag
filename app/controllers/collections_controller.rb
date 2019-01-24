require 'zip'

class CollectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_collection, only: [:show, :edit, :update, :destroy, :download, 
                                :empty, :delete_all_annotations, :done_all, :reorder]
  before_action :set_top_menu
  helper_method :sort_column, :sort_direction

  # GET /collections
  # GET /collections.json
  def index
    breadcrumb_for_collections
    @collections = @user.collections.all
    if params[:name].present?
      @collections = @collections.where("name = ?", params[:name])
    end
    @collections = @collections.order(sort_column + " " + sort_direction)

    respond_to do |format|
      format.html
      format.json {render json:@collections.as_json(only: [:id, :name, :documents_count])}
    end
  end

  def partial
    @collections = @user.collections.all
    @collections = @collections.order(sort_column + " " + sort_direction)
    respond_to do |format|
      format.html {render layout: false}
      format.json {render json:@collections.as_json(only: [:id, :name, :documents_count])}
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
    Collection.load_samples(@user)
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
    @collection = @user.collections.new(collection_params)
    @collection.order_no = @user.collections.size
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

  def reorder
    @user = @collection.user

    if params[:batch_id].present?
      Collection.transaction do 
        last_order_no = @collection.documents.where("order_no < 999999").maximum('order_no')
        last_order_no = 0 if last_order_no.nil?
        if params[:batch_id] == "999999"
          no = last_order_no + 1
          @collection.documents.where("order_no = 999999").order("batch_id ASC, batch_no DESC, id ASC").each do |d|
            d.order_no = no
            d.save!
            no += 1
          end
        else
          @collection.documents
            .where("batch_id = ? and order_no = 999999", params[:batch_id])
            .update_all("order_no = batch_no + #{last_order_no}")
        end
      end
    else
      src = @collection.order_no
      if params[:dest] == "last"
        dest = @user.collections.size
      else
        dest = params[:dest].to_i
      end
      Collection.transaction do 
        if dest > @collection.order_no
          @user.collections.where("order_no > ? and order_no <= ?", src, dest).update_all("order_no = order_no - 1")
          @collection.order_no = dest
          @collection.save!
        elsif dest < @collection.order_no
          @user.collections.where("order_no >= ? and order_no < ?", dest, src).update_all("order_no = order_no + 1")
          @collection.order_no = dest
          @collection.save!
        end
      end
    end
    respond_to do |format|
      format.html { redirect_back fallback_location: collections_path, notice: 'The collection was successfully reordered.' }
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
      @collection = Collection.find(params[:id])

      unless @collection.available?(@current_user)
        respond_to do |format|
          format.html { redirect_back fallback_location: collections_path, error: "Cannot access the document"}
          format.json { render json: {msg: 'Cannot access document'}, status: 401 }
        end    
        return false
      end
    end

    def set_user
      if params[:user_id].present? && @current_user.super_admin?
        @user = User.find(params[:user_id]) 
      else
        @user = @current_user
      end
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def collection_params
      params.require(:collection).permit(:name, :note, :source, :cdate, :key)
    end

    def set_top_menu
      @top_menu = 'collections'
    end

    def sort_column
      Collection.column_names.include?(params[:sort]) ? params[:sort] : "id"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
    end
end

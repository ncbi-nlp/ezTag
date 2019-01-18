require 'open-uri'
class Collection < ApplicationRecord
  belongs_to :user
  has_many :documents, dependent: :destroy
  has_many :entity_types, dependent: :destroy
  has_many :tasks,-> { order 'created_at desc' }, dependent: :destroy
  validates :name, presence: true

  attr_accessor :model_url

  def available?(user)
    self.user_id == user.id || user.super_admin?
  end

  def self.load_samples(user)
    Collection.transaction do
      training_set = user.collections.create!({name: 'Sample Training Set', key: 'samples'})
      training_set.entity_types.create({name: 'Disease', color: "#FFCCCC"})
      test_set = user.collections.create!({name: 'Sample Test Set', key: 'samples'})
      test_set.entity_types.create({name: 'Disease', color: "#FFCCCC"})
      training_set.upload_from_file(Rails.root.join("public", "sample_training.xml"), 1)
      test_set.upload_from_file(Rails.root.join("public", "sample_test.xml"), 1)
      LexiconGroup.load_samples(user) unless user.has_sample_lexicons?
    end
  end

  def upload_from_file(file, batch_id, replace_did = nil)
    begin
      Collection.transaction do 
        if replace_did.present?
          self.documents.where("did = ?", replace_did).destroy_all
        end
        if file.respond_to?(:read)
          xml = file.read
        elsif file.respond_to?(:path)
          xml = File.read(file.path)
        else
          logger.error "Bad file: #{file.class.name}: #{file.inspect}"
          return ["Failed to read file", nil]
        end

        begin
          bioc = SimpleBioC.from_xml_string(xml)
        rescue => error
          Rollbar.error(error)
          return [error, nil]
        end

        dids = []
        batch_no = 1
        bioc.documents.each do |d|
          doc = Document.new
          doc.batch_id = batch_id
          doc.batch_no = batch_no
          doc.save_document(d, bioc, self)
          dids << doc.did
          batch_no += 1
        end
        return [nil , dids]   
      end
    rescue => e
      Rollbar.error(error)
      return [error, nil]
    end
  end

  def upload_from_pmids(pmids, batch_id, id_map)
    logger.debug("PMID=#{pmids.inspect} | batch_id = #{batch_id} | id_map = #{id_map.inspect}")

    begin
      begin
        if pmids.size > 0 && pmids[0].start_with?('PMC')
          url = "https://www.ncbi.nlm.nih.gov/bionlp/RESTful/pmcoa.cgi/BioC_xml/#{URI.escape(pmids.join('|'))}/unicode"
          logger.debug("URL == #{url}")
        else
          url = "https://www.ncbi.nlm.nih.gov/bionlp/RESTful/pubmed.cgi/BioC_xml/#{URI.escape(pmids.join('|'))}/unicode"
        end
        xml = open(url).read
        # logger.debug(xml)
        bioc = SimpleBioC.from_xml_string(xml)
      rescue Nokogiri::XML::SyntaxError => e
        Rollbar.error(e)
        puts "caught exception: #{e}"
        return [e, nil]
      rescue => error
        Rollbar.error(error)
        puts "caught exception: #{e2}"
        return [error, nil]
      end
      dids = []
      bioc.documents.each do |d|
        doc = Document.new
        if bioc.source == "PMC"
          did = "PMC#{d.id}"
        else
          did = d.id
        end
        doc.batch_id = batch_id
        doc.batch_no = id_map[did]
        doc.save_document(d, bioc, self)
        dids << did
      end
      return [nil, dids]
    rescue => e
      Rollbar.error(error)
      return [error, nil]
    end
  end

  def update_annotation_count
    results = ActiveRecord::Base.connection.execute("
      UPDATE collections SET annotations_count = IFNULL((
        SELECT sum(annotations_count) 
        FROM documents 
        WHERE collection_id = #{self.id}
      ), 0)
      WHERE id = #{self.id}
    ")
  end

  def create_task(params)
    return nil if self.busy?
    task = nil
    val = params[:task]
    Collection.transaction do 
      task = self.tasks.new
      task.user_id = self.user_id

      mode = val[:task_type] || "0"
      mode = mode.to_i
      task.task_type = mode

      if mode == 1
        # training
        task.tagger = "TaggerOne"
        model = Model.new
        model.user_id = self.user_id
        model.name = params[:output_model_name] || "No name"
        model.save
        task.model_id = model.id
        task.has_model = true
        if val[:lexicon_group_id] != "0"
          task.lexicon_group_id = val[:lexicon_group_id].to_i
          task.has_lexicon_group = true
        end
      else
        # annotating
        if params[:with] == "model" 
          task.tagger = "TaggerOne"
          task.task_type = 2
          if pre_trained_model?(val[:model])
            task.pre_trained_model = val[:model]
          elsif val[:model] != "0"
            task.model_id = val[:model].to_i
            task.has_model = true
          end
        elsif params[:with] == "lexicon" 
          task.tagger = "Lexicon"
          task.lexicon_group_id = val[:lexicon_group_id].to_i
          task.has_lexicon_group = true
        end
      end
      task.status = "requested" 
      if task.save
        return task
      else
        logger.debug(task.errors.inspect)
      end
      return task
    end
    return nil
  end

  def status
    task = self.tasks.first
    if task.nil?
      'ready'
    else
      task.status
    end
  end

  def busy?(st = nil)
    if st.nil?
      st = self.status
    end
    st == 'requested' || st == 'processing'
  end

  def task_available?(st = nil)
    if st.nil?
      st = self.status
    end
    !self.busy?(st) && self.documents_count > 0
  end
  
  def status_with_icon(st = nil)
    if st.nil?
      st = self.status
    end
    if self.busy?(st)
      "<i class='icon refresh loading'></i> #{st.capitalize}".html_safe
    else
      "<i class='icon checkmark'></i> #{st.capitalize}".html_safe
    end
  end

  def has_annotations?
    size = documents.size

    for i in (0...size)
      return true if !documents[i].nil? && documents[i].annotations_count > 0
    end
    return false
  end

  def has_annotations_on_done_documents?
    size = documents.size

    for i in (0...size)
      return true if !documents[i].nil? && documents[i].done && documents[i].annotations_count > 0
    end
    return false
  end

  def entity_type(name) 
    if @etype_map.nil?
      @etype_map = {}
      self.entity_types.each do |t|
        @etype_map[t.name] = t
      end
    end
    etype =  @etype_map[name]
    if etype.nil?
      t = self.entity_types.create({name: name});
      @etype_map[name] = t
      etype = t
    end
    etype
  end

  def pre_trained_model?(name)
    return name == "Chemical" || name == "Disease" || name == "Chemical/Disease" ||
           name == "Gene" || name == "Species" || name == "Variation" || name == "All"
  end
end

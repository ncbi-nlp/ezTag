require 'rollbar'
class Document < ApplicationRecord
  belongs_to :collection, counter_cache: true
  
  def save_document(d, bioc, collection)
    self.did = d.id
    self.did_no = self.did.to_i
    self.collection_id = collection.id
    self.title = get_first_text_from_bioc(d)
    self.key = bioc.key
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.doc.create_internal_subset( 'collection', nil, 'BioC.dtd' )
      xml.collection {
        xml.source bioc.source
        xml.date bioc.date
        xml.key bioc.key
        BioCWriter::write_infon(xml, bioc)
        BioCWriter::write_document(xml, d)
      }
    end
    self.xml = builder.to_xml({save_with: 1})
    self.save
    self.handle_update_xml(d)
  end

  def save_document_from_pmid(pmid, collection)
    begin
      xml = open("https://www.ncbi.nlm.nih.gov/CBBresearch/Lu/Demo/RESTful/tmTool.cgi/Empty/#{pmid}/BioC/").read
      logger.debug(xml)
      bioc = SimpleBioC.from_xml_string(xml)
    rescue Nokogiri::XML::SyntaxError => e
      Rollbar.error(e)
      puts "caught exception: #{e}"
      return e
    rescue => error
      Rollbar.error(error)
      puts "caught exception: #{e2}"
      return error
    end
    self.collection_id = collection.id
    d = bioc.documents[0]
    self.title = get_first_text_from_bioc(d)
    self.did = d.id
    self.did_no = self.did.to_i
    self.key = bioc.key
    self.xml = xml
    self.save
    self.handle_update_xml(d)
    return nil
  end

  def save_xml(bioc)
    self.adjust_offset(true)
    self.xml = SimpleBioC.to_xml(bioc)
    self.save
    self.handle_update_xml(nil)
  end

  def gen_id
    max = 0
    self.bioc_doc.all_annotations.each do |a|
      no = a.id.to_i
      if no > max 
        max = no
      end
    end
    "#{max + 1}"
  end

  def annotate_all_by_text(text, entity_type, concept, case_sensitive, whole_word)
    exist_offsets = []
    currents_annotations = self.bioc_doc.all_annotations.each do |a|
      if a.text.upcase == text.upcase
        a.locations.each do |l|
          exist_offsets << l.offset.to_i
        end
      end
    end
    if whole_word && case_sensitive
      pattern = /\b#{Regexp.escape(text)}\b/
    elsif whole_word
      pattern = /\b#{Regexp.escape(text)}\b/i
    elsif case_sensitive
      pattern = /#{Regexp.escape(text)}/
    else
      pattern = /#{Regexp.escape(text)}/i
    end
    Document.transaction do 
      a = nil
      self.bioc_doc.passages.each do |p|
        if p.text.nil?
          p.sentences.each do |s|
            positions = find_all_locations(s, pattern)
            positions.each do |offset|
              next if exist_offsets.include?(offset)
              a = SimpleBioC::Annotation.new(s)
              a.id = gen_id
              a.text = s.text[offset - s.offset, text.length]
              a.infons["type"] = entity_type
              a.infons["identifier"] = concept
              l = SimpleBioC::Location.new(a)
              l.offset = offset
              l.length = text.length
              a.locations << l
              s.annotations << a
            end
          end
        else 
          positions = find_all_locations(p, pattern)
          positions.each do |offset|
            next if exist_offsets.include?(offset)
            a = SimpleBioC::Annotation.new(p)
            a.id = gen_id
            a.text = p.text[offset - p.offset, text.length]
            a.infons["type"] = entity_type
            a.infons["identifier"] = concept
            l = SimpleBioC::Location.new(a)
            l.offset = offset
            l.length = text.length
            a.locations << l
            p.annotations << a
          end
        end
      end
      self.save_xml(self.bioc)
      return a
    end
  end

  def add_annotation(text, offset, entity_type, concept)
    Document.transaction do 
      a = nil
      self.bioc_doc.passages.each do |p|
        Rails.logger.debug("TEXT #{text} | P TEXT #{p.text}")
        if p.text.nil?
          p.sentences.each do |s|
            if s.offset <= offset && s.offset + s.text.length >= offset + text.length
              a = SimpleBioC::Annotation.new(s)
              a.id = gen_id
              a.text = text
              a.infons["type"] = entity_type
              a.infons["identifier"] = concept
              l = SimpleBioC::Location.new(a)
              l.offset = offset
              l.length = text.length
              a.locations << l
              s.annotations << a
            end
          end
        else 
          if p.offset <= offset && p.offset + p.text.length >= offset + text.length
            a = SimpleBioC::Annotation.new(p)
            a.id = gen_id
            a.text = text
            a.infons["type"] = entity_type
            a.infons["identifier"] = concept
            l = SimpleBioC::Location.new(a)
            l.offset = offset
            l.length = text.length
            a.locations << l
            p.annotations << a
          end
        end
      end
      self.save_xml(self.bioc)
      return a
    end
  end


  def delete_annotation(mode, id, offset, entity_type, concept)
    Document.transaction do 
      self.bioc_doc.passages.each do |p|
        p.sentences.each do |s|
          delete_annotation_in_document(s, mode, id, offset, entity_type, concept)
        end
        delete_annotation_in_document(p, mode, id, offset, entity_type, concept)      
      end
      self.save_xml(self.bioc)
    end
  end

  def delete_all_annotations
    Document.transaction do 
      self.bioc_doc.passages.each do |p|
        p.sentences.each do |s|
          s.annotations.clear
        end
        p.annotations.clear
      end
      self.save_xml(self.bioc)
    end
    return true
  end

  def update_concept_in_document(node, old, entity_type, concept)
    node.annotations.each do |a|
      entity = EntityUtil.get_annotation_entity(a)
      logger.debug("#{a.id.inspect} #{entity.inspect}")
      if entity[:type] == old[:type] && entity[:id] == old[:id]
        logger.debug("FOUND id")
        EntityUtil.update_annotation_entity(a, entity_type, concept)
      end
    end
  end

  def update_mention_in_document(node, id, entity_type, concept)
    node.annotations.each do |a|
      logger.debug("#{a.id.inspect} ==? #{id.inspect}")
      if a.id == id
        logger.debug("FOUND id")
        EntityUtil.update_annotation_entity(a, entity_type, concept)
      end
    end
  end
  def update_concept(id, entity_type, concept)
    old_a = nil
    self.bioc_doc.all_annotations.each do |a|
      old_a = a if a.id == id
    end
    old_entity = EntityUtil.get_annotation_entity(old_a)

    Document.transaction do 
      self.bioc_doc.passages.each do |p|
        p.sentences.each do |s|
          update_concept_in_document(s, old_entity, entity_type, concept)
        end
        update_concept_in_document(p, old_entity, entity_type, concept)
      end
      self.save_xml(self.bioc)
    end
  end

  def update_mention(id, entity_type, concept)
    Document.transaction do 
      self.bioc_doc.passages.each do |p|
        p.sentences.each do |s|
          update_mention_in_document(s, id, entity_type, concept)
        end
        update_mention_in_document(p, id, entity_type, concept)
      end
      self.save_xml(self.bioc)
    end
  end
  def bioc
    if @bioc.nil?
      @bioc = SimpleBioC.from_xml_string(self.xml)
    end
    @bioc
  end
  
  def bioc_doc
    self.bioc.documents[0]
  end

  def adjust_offset(needFix)
    doc = self.bioc_doc
    doc.passages.each do |p|
      adjust_annotation_offsets(p, needFix)
      p.sentences.each do |s|
        adjust_annotation_offsets(s, needFix)
      end
    end
  end

  def adjust_annotation_offsets(obj, needFix)
    return if obj.nil? || obj.annotations.nil?
    ret = []
    obj.annotations.each do |a|
      positions = find_all_locations(obj, a.text)
      next if a.locations.nil?
      a.locations.each do |l|
        next if l.nil? || l == false
        candidate = choose_offset_candidate(l.offset, positions)
        if candidate.to_i != l.offset.to_i
          val = a.infons["error:misaligned:#{a.id}"] || ""
          arr = val.split(",")
          arr << "#{l.offset}->#{candidate}"
          a.infons["error:misaligned:#{a.id}"] = arr.join(",")
          ret << [a.id, l.offset, l.length, candidate]
          if needFix
            l.offset = candidate
          end
        end
      end
    end
    return ret
  end
  
  def atype(name)
    self.collection.entity_type(name)
  end

  def find_all_locations(obj, text)
    positions = []
    return positions if obj.nil? || obj.text.nil?
    pos = obj.text.index(text)
    until pos.nil? 
      positions << (pos + obj.offset)
      pos = obj.text.index(text, pos + 1)
    end
    return positions
  end

  def choose_offset_candidate(offset, positions)
    return offset if positions.nil?
    min_diff = 99999
    offset = offset.to_i
    ret = offset
    positions.each do |p|
      diff = (offset - p).abs
      if diff < min_diff
        ret = p 
        min_diff = diff
      end
    end
    return ret
  end

  def handle_update_xml(doc)
    if doc.nil?
      doc = self.bioc_doc
    end
    annotations = doc.all_annotations 
    self.annotations_count = annotations.size
    self.save

    self.collection.update_annotation_count
  end

  def get_psize(p)
    self.get_ptext(p).size
  end

  def get_ptext(p)
    if p.text.blank?
      p.sentences.map{|s| s.text}.join(" ")
    else
      p.text
    end
  end
  def get_class_from_passage(p)
    cls = []
    p.annotations.each do |a|
      cls = cls | [get_class_from_annotation(a)]
    end
    p.sentences.each do |s|
      s.annotations.each do |a|
        cls = cls | [get_class_from_annotation(a)]
      end
    end
    return cls.uniq
  end
  def get_class_from_annotation(a)
    type = a.infons['type']
    cls_name = case type.downcase
    when 'gene'
      "G"
    when 'organism'
      "O"
    when 'ppimention','ppievidence'
      "EP"
    when 'geneticinteractiontype', 'gievidence', 'gimention'
      "EG"
    when 'experimentalmethod'
      "EM"
    when 'none'
      ""
    else
      "E"
    end unless type.nil?

    return cls_name
  end
  def outline
    root = {children: []}
    last_in_levels = [root]
    last_item = nil
    self.bioc_doc.passages.each_with_index do |p, index|
      next if p.infons["type"].nil?

      result = p.infons["type"].match(/title_(\d+)/)
      if result.present?
        level = result[1].strip.to_i
        item_text = "title"
      elsif %w(front abstract title).include?(p.infons["type"])
        level = 1
        item_text = p.infons["type"]
      else
        if !last_item.nil?
          last_item[:cls] = last_item[:cls] | get_class_from_passage(p)
          next
        else
          level = 1
          item_text = p.infons["type"]
        end
      end

      desc = self.get_ptext(p)[0..30] 
      item = {id: index, text: item_text, description: desc, children: [], level: level, cls: []}
      
      last_item = item
      last_item[:cls] = last_item[:cls] | get_class_from_passage(p)
      last_in_levels[level] = item
      plevel = level - 1
      while (plevel > 0 && last_in_levels[plevel].nil?) do
        plevel = plevel - 1
      end
      p = last_in_levels[plevel]
      p[:children] << item
    end

    root[:children]
  end

  def verify
    result = []
    id_map = {}

    doc = self.bioc_doc
    doc.passages.each do |p|
      p.sentences.each do |s|
        check_duplicated_id(s.annotations, result, 'annotation', id_map)
        check_duplicated_id(s.relations, result, 'annotation', id_map)
      end
      check_duplicated_id(p.annotations, result, 'annotation', id_map)
      check_duplicated_id(p.relations, result, 'annotation', id_map)
    end
    doc.passages.each do |p|
      p.sentences.each do |s|
        check_annotation_location(s, result)
        check_relation_ref(s, result, id_map)
      end
      check_annotation_location(p, result) unless p.text.nil?
      check_relation_ref(p, result, id_map)
    end

    result
  end

  def check_duplicated_id(coll, result, type, id_map)
    coll.each do |n|
      if id_map[n.id].nil?
        id_map[n.id] = 1
      else
        result << "#{n.id}: this #{type} ID is duplicated"
      end
    end
  end

  def check_annotation_location(obj, result)
    misaligned = adjust_annotation_offsets(obj, true)
    misaligned.each do |item|
      result << "The annotation #{item[0]} is misaligned [#{item[1]}:#{item[2]}] (auto-fixed to [#{item[3]}:#{item[2]}])"
    end
    obj.annotations.each do |a|
      a.locations.each do |l|
        start_pos = l.offset.to_i - obj.offset
        end_pos = start_pos + l.length.to_i
        text = obj.text[start_pos...end_pos]
        if text != a.text
          result <<  "The annotation #{a.id} is misaligned [#{l.offset}:#{l.length}] (the text in annotation '<b>#{a.text}</b>' is different from the one at the location '<b>#{text}</b>')"
        end
      end
    end
  end

  def check_relation_ref(obj, result, id_map) 
    obj.relations.each do |r|
      r.nodes.each do |n|
        if id_map[n.refid].nil?
          result << "The relation #{r.id} refers non-existing nodes (refid: #{n.refid})"
        end
      end
    end
  end


  private
  def get_first_text_from_bioc(doc)
    doc.passages.each do |p|
      p.sentences.each do |s|
        return s.text
      end
      return p.text
    end
  end

  def delete_annotation_in_document(node, mode, id, offset, entity_type, concept)
    logger.debug("NODE offset #{node.offset} #{mode} #{node.annotations.size}")
    node.annotations.delete_if do |a|
      if mode == "concept" 
        e = EntityUtil.get_annotation_entity(a)
        if e[:type] == entity_type && e[:id] == concept
          true
        else
          false
        end
      else
        if a.id == id
          a.locations.delete_if do |l|
            l.offset.to_i == offset
          end
          if a.locations.empty?
            true
          else
            false
          end
        else
          false
        end
      end
    end
    logger.debug("END NODE")
  end
end

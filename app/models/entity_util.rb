class EntityUtil
  def self.get_annotation_entity(annotation)
    entity_type = annotation.infons["type"] || "" 
    concept = annotation.infons["identifier"] || ""
    return {type: entity_type, id: concept}  
    # return {type: "", id: ""} if entity_type.nil?

    # c = annotation.infons[entity_type + "ID"]
    # return {type: entity_type, id: c} unless c.nil?

    # annotation.infons.each do |k, v|
    #   if k.include?("ID") || k.include?("Id")
    #     return {type: entity_type, id: v}
    #   end 
    # end
    # {type: entity_type, id: ""}
  end

  def self.update_annotation_entity(annotation, type, concept, note = "") 
    annotation.infons["type"] = type unless type.nil?
    annotation.infons["identifier"] = concept unless concept.nil?
    if note.present?
      annotation.infons["note"] = note 
    else
      annotation.infons.delete('note')
    end
    # unless annotation.infons[type + "ID"].nil?
    #   annotation.infons[type + "ID"] = concept
    #   return
    # end
    # annotation.infons.each do |k, v|
    #   if k.include?("ID") || k.include?("Id")
    #     annotation.infons[k] = concept
    #   end 
    # end      
  end
end
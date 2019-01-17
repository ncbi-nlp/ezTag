p_offset = @document.bioc_doc.passages.map{|p, index| p.offset.to_i }

json.annotations @document.bioc_doc.all_annotations.each do |a|
  entity = EntityUtil.get_annotation_entity(a)
  text = a.text
  a.locations.each do |l|
    p_idx = 0
    
    while p_idx < p_offset.size - 1
      break if p_offset[p_idx] > l.offset.to_i
      p_idx += 1
    end
    json.id a.id
    json.type entity[:type]
    json.concept entity[:id]
    json.annotator entity[:annotator]
    json.updated_at entity[:updated_at]
    json.text a.text
    json.note a.infons["note"]
    json.offset l.offset
    json.passage "#passage-#{p_idx - 1}"
  end
end

json.entity_types @entity_types.each do |e|
  json.name e.name
  json.color "##{e.color}"
end

unless @ret.nil?
  entity = EntityUtil.get_annotation_entity(@ret)
  json.annotation do 
    p_idx = 0
    
    while p_idx < p_offset.size - 1
      break if p_offset[p_idx] > @ret.locations[0].offset.to_i
      p_idx += 1
    end
    json.id @ret.id
    json.type entity[:type]
    json.concept entity[:id]
    json.annotator entity[:annotator]
    json.updated_at entity[:updated_at]
    json.text @ret.text
    json.offset @ret.locations[0].offset
    json.passage "#passage-#{p_idx - 1}"
  end
end

json.extract! document, :id, :collection_id, :did, :user_updated_at, :tool_updated_at, :annotations_count, :created_at, :updated_at
json.url document_url(document, format: :json)
json.extract! collection, :id, :user_id, :name, :documents_count, :note, :source, :cdate, :key, :status_with_icon, :created_at, :updated_at
json.url collection_url(collection, format: :json)
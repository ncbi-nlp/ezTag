json.extract! user, :id, :session_str, :ip, :created_at, :updated_at
json.url user_url(user, format: :json)
json.extract! webhook, :id, :source_name, :data, :status, :created_at, :updated_at
json.url webhook_url(webhook, format: :json)

class CreateWebhooks < ActiveRecord::Migration[5.0]
  def change
    create_table :webhooks do |t|
      t.string :source_name
      t.jsonb :data
      t.string :status, default: :pending

      t.timestamps
    end
  end
end

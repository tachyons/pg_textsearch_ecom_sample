class CreateSearchLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :search_logs do |t|
      t.string :query, null: false
      t.jsonb :filters_json, default: {}
      t.integer :results_count, default: 0
      t.integer :latency_ms, default: 0
      t.bigint :user_id
      t.timestamps
    end

    add_index :search_logs, :query
    add_index :search_logs, :created_at
    add_index :search_logs, :user_id
  end
end

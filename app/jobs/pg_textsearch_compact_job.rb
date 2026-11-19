class PgTextsearchCompactJob < ApplicationJob
  queue_as :background

  INDEXES = %w[
    products_active_search_idx
    products_active_name_idx
    products_active_desc_idx
  ].freeze

  def perform
    INDEXES.each do |idx|
      PgTextsearch::Maintenance.compact_step(idx) if PgTextsearch::Maintenance.needs_compaction?(idx)
    end
  end
end

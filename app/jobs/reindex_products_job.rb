class ReindexProductsJob < ApplicationJob
  queue_as :background

  def perform(record_type, record_id)
    record = record_type.constantize.find_by(id: record_id)
    return unless record

    case record_type
    when "Brand"
      record.products.find_in_batches(batch_size: 100) { |batch| batch.each(&:refresh_search_text!) }
    when "Category"
      record.products.find_in_batches(batch_size: 100) { |batch| batch.each(&:refresh_search_text!) }
    when "Label"
      record.products.find_in_batches(batch_size: 100) { |batch| batch.each(&:refresh_search_text!) }
    end
  end
end
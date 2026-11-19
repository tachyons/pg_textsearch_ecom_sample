class SearchLogJob < ApplicationJob
  queue_as :background

  def perform(query:, filters:, results_count:, latency_ms:, user_id: nil)
    SearchLog.create!(
      query: query,
      filters_json: filters,
      results_count: results_count,
      latency_ms: latency_ms,
      user_id: user_id
    )
  end
end
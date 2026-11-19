module Catalog
  class Search
    PRICE_BUCKETS = [
      { key: "under_50",  label: "Under $50",   min: 0,     max: 4999 },
      { key: "50_100",    label: "$50 – $100",  min: 5000,  max: 9999 },
      { key: "100_250",   label: "$100 – $250", min: 10000, max: 24999 },
      { key: "over_250",  label: "$250+",       min: 25000, max: nil }
    ].freeze

    Result = Data.define(:products, :total_count, :facets, :aggregates, :latency_ms)

    def initialize(params)
      @query        = params[:q].to_s.strip
      @category_ids = Array(params[:category_ids]).reject(&:blank?).map(&:to_i)
      @brand_ids    = Array(params[:brand_ids]).reject(&:blank?).map(&:to_i)
      @label_ids    = Array(params[:label_ids]).reject(&:blank?).map(&:to_i)
      @price_bucket = params[:price_bucket].presence
      @min_price    = params[:min_price].presence&.to_i
      @max_price    = params[:max_price].presence&.to_i
      @min_rating   = params[:min_rating].presence&.to_f
      @in_stock     = ActiveModel::Type::Boolean.new.cast(params[:in_stock])
      @sort         = params[:sort].presence || (@query.present? ? "relevance" : "popular")
      @page         = [params[:page].to_i, 1].max
      @per_page     = (params[:per_page] || 24).to_i.clamp(1, 60)
    end

    def call
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      base_matched = matched_scope
      filtered     = apply_filters(base_matched)

      total_count = filtered.count
      products    = apply_sorting(filtered)
                      .includes(:brand, :category, :labels)
                      .offset((@page - 1) * @per_page)
                      .limit(@per_page)
                      .to_a

      facets     = build_facets(base_matched)
      aggregates = build_aggregates(filtered)
      latency_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round

      Result.new(products:, total_count:, facets:, aggregates:, latency_ms:)
    end

    private

    # Base scope: active products, narrowed to BM25 matches if a query is present
    def matched_scope
      scope = Product.active
      return scope if @query.blank?

      terms = Product.search_terms(@query)
      return scope.none if terms.blank?

      if terms.length < 3
        # 1-2 char terms are dropped by the english text config as stop words
        scope.where("search_text ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(terms)}%")
      else
        # prefix matching via @@ to_tsquery (pg_textsearch >= 0.1.5)
        scope.where(Product.bm25_match(:search_text, terms, index: :products_active_search_idx, prefix: true))
      end
    end

    def apply_filters(scope, exclude: nil)
      scope = scope.where(category_id: @category_ids) if @category_ids.any? && exclude != :category
      scope = scope.where(brand_id: @brand_ids)       if @brand_ids.any?    && exclude != :brand

      if @label_ids.any? && exclude != :label
        scope = scope.where(
          id: ProductLabel.where(label_id: @label_ids).select(:product_id)
        )
      end

      if exclude != :price
        scope = apply_price_filter(scope)
      end

      scope = scope.where("rating_avg >= ?", @min_rating) if @min_rating && exclude != :rating
      scope = scope.in_stock if @in_stock && exclude != :stock
      scope
    end

    def apply_price_filter(scope)
      if (bucket = PRICE_BUCKETS.find { |b| b[:key] == @price_bucket })
        scope = scope.where("price_cents >= ?", bucket[:min]) if bucket[:min]
        scope = scope.where("price_cents <= ?", bucket[:max]) if bucket[:max]
      else
        scope = scope.where("price_cents >= ?", @min_price * 100) if @min_price
        scope = scope.where("price_cents <= ?", @max_price * 100) if @max_price
      end
      scope
    end

    def apply_sorting(scope)
      if @query.present? && @sort == "relevance"
        # Ranking/highlighting only: matched_scope already did the WHERE
        scope.bm25_search(
          :search_text,
          @query,
          index: :products_active_search_idx,
          select_score: true,
          filter: false,
          highlight: { start_sel: "<mark>", stop_sel: "</mark>", max_words: 28 },
          ranked_by: ":bm25 - (0.05 * LN(products.popularity_score + 1))",
          order_within_rank: "products.rating_avg DESC"
        )
      else
        case @sort
        when "price_asc"  then scope.order(price_cents: :asc)
        when "price_desc" then scope.order(price_cents: :desc)
        when "rating"     then scope.order(rating_avg: :desc, reviews_count: :desc)
        when "newest"     then scope.order(created_at: :desc)
        else                   scope.order(popularity_score: :desc)
        end
      end
    end

    # Disjunctive facet counts
    def build_facets(base_matched)
      {
        categories: count_categories(apply_filters(base_matched, exclude: :category)),
        brands:     count_brands(apply_filters(base_matched, exclude: :brand)),
        labels:     count_labels(apply_filters(base_matched, exclude: :label)),
        prices:     count_price_buckets(apply_filters(base_matched, exclude: :price)),
        ratings:    count_ratings(apply_filters(base_matched, exclude: :rating)),
        in_stock:   apply_filters(base_matched, exclude: :stock).in_stock.count
      }
    end

    def count_categories(scope)
      counts = scope.group(:category_id).count
      Category.where(id: counts.keys).order(:name).map { |c| [c, counts[c.id]] }
    end

    def count_brands(scope)
      counts = scope.group(:brand_id).count
      Brand.where(id: counts.keys).order(:name).map { |b| [b, counts[b.id]] }
    end

    def count_labels(scope)
      counts = ProductLabel.where(product_id: scope.select(:id)).group(:label_id).count
      Label.where(id: counts.keys).order(:name).map { |l| [l, counts[l.id]] }
    end

    def count_price_buckets(scope)
      sql = Arel.sql(<<~SQL.squish)
        CASE
          WHEN price_cents < 5000  THEN 'under_50'
          WHEN price_cents < 10000 THEN '50_100'
          WHEN price_cents < 25000 THEN '100_250'
          ELSE 'over_250'
        END
      SQL
      counts = scope.group(sql).count
      PRICE_BUCKETS.map { |b| b.merge(count: counts.fetch(b[:key], 0)) }
    end

    def count_ratings(scope)
      [4, 3, 2].map do |stars|
        { stars: stars, count: scope.where("rating_avg >= ?", stars).count }
      end
    end

    # Summary aggregates for the current result set
    def build_aggregates(scope)
      min_c, max_c, avg_c, avg_r = scope.pick(
        Arel.sql("MIN(price_cents)"),
        Arel.sql("MAX(price_cents)"),
        Arel.sql("AVG(price_cents)"),
        Arel.sql("AVG(rating_avg)")
      )
      {
        min_price_cents: min_c.to_i,
        max_price_cents: max_c.to_i,
        avg_price_cents: avg_c.to_i,
        avg_rating: avg_r.to_f.round(2)
      }
    end
  end
end
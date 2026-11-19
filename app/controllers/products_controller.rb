class ProductsController < ApplicationController
  def index
    @search_params = search_params
    @result = Catalog::Search.new(@search_params).call

    @query        = @search_params[:q].to_s.strip
    @category_ids = Array(@search_params[:category_ids]).reject(&:blank?).map(&:to_i)
    @brand_ids    = Array(@search_params[:brand_ids]).reject(&:blank?).map(&:to_i)
    @label_ids    = Array(@search_params[:label_ids]).reject(&:blank?).map(&:to_i)
    @price_bucket = @search_params[:price_bucket].presence
    @min_price    = @search_params[:min_price].presence&.to_i
    @max_price    = @search_params[:max_price].presence&.to_i
    @min_rating   = @search_params[:min_rating].presence&.to_f
    @in_stock     = ActiveModel::Type::Boolean.new.cast(@search_params[:in_stock])
    @sort         = @search_params[:sort].presence || (@query.present? ? "relevance" : "popular")
    @page         = [ @search_params[:page].to_i, 1 ].max
    @per_page     = (@search_params[:per_page] || 24).to_i.clamp(1, 60)

    if @search_params[:q].present?
      SearchLogJob.perform_later(
        query: @search_params[:q],
        filters: @search_params.except(:q, :page).to_h,
        results_count: @result.total_count,
        latency_ms: @result.latency_ms,
        user_id: nil
      )
    end
  end

  def show
    @product = Product.active.includes(:brand, :category, :labels).find_by!(slug: params[:slug])
    @related_products = @product.related_products(limit: 4)
  end

  def autocomplete
    @query = params[:q].to_s.strip

    @suggestions = if @query.length >= 2
      Product.active
             .bm25_search(:name, @query, index: :products_active_name_idx)
             .includes(:category, :brand)
             .limit(6)
    else
      Product.none
    end

    render layout: false
  end

  private

  def search_params
    params.permit(
      :q, :sort, :page, :price_bucket, :min_price, :max_price, :min_rating, :in_stock,
      category_ids: [], brand_ids: [], label_ids: []
    )
  end
end

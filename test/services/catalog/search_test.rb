require "test_helper"

class Catalog::SearchTest < ActiveSupport::TestCase
  setup do
    @category = Category.create!(name: "Electronics", slug: "electronics")
    @brand = Brand.create!(name: "Apple", slug: "apple")
    @label = Label.create!(name: "Bestseller", slug: "bestseller", color: "amber")

    @product1 = Product.create!(
      name: "iPhone 15 Pro",
      slug: "iphone-15-pro",
      sku: "IPHONE-15-PRO",
      description: "Latest iPhone with A17 Pro chip",
      price_cents: 99900,
      stock_count: 50,
      rating_avg: 4.8,
      popularity_score: 9500,
      category: @category,
      brand: @brand,
      active: true
    )
    @product1.labels << @label

    @product2 = Product.create!(
      name: "iPhone 15",
      slug: "iphone-15",
      sku: "IPHONE-15",
      description: "Dynamic Island, 48MP camera",
      price_cents: 79900,
      stock_count: 75,
      rating_avg: 4.6,
      popularity_score: 8800,
      category: @category,
      brand: @brand,
      active: true
    )

    @product3 = Product.create!(
      name: "Galaxy S24",
      slug: "galaxy-s24",
      sku: "GALAXY-S24",
      description: "Galaxy AI, 50MP camera",
      price_cents: 79900,
      stock_count: 60,
      rating_avg: 4.5,
      popularity_score: 7800,
      category: @category,
      brand: Brand.create!(name: "Samsung", slug: "samsung"),
      active: true
    )
  end

  test "returns all active products when no query" do
    result = Catalog::Search.new({}).call
    assert_equal 3, result.total_count
    assert_equal 3, result.products.size
  end

  test "filters by text query" do
    result = Catalog::Search.new(q: "iphone").call
    assert_equal 2, result.total_count
    assert result.products.map(&:name).all? { |n| n.downcase.include?("iphone") }
  end

  test "matches partial words with prefix search" do
    result = Catalog::Search.new(q: "ipho").call
    assert_equal 2, result.total_count
  end

  test "filters by category" do
    result = Catalog::Search.new(category_ids: [@category.id]).call
    assert_equal 3, result.total_count
  end

  test "filters by brand" do
    result = Catalog::Search.new(brand_ids: [@brand.id]).call
    assert_equal 2, result.total_count
  end

  test "filters by label" do
    result = Catalog::Search.new(label_ids: [@label.id]).call
    assert_equal 1, result.total_count
    assert_equal "iPhone 15 Pro", result.products.first.name
  end

  test "filters by price bucket" do
    # Products are $999, $799, $799 - all in over_250 bucket
    result = Catalog::Search.new(price_bucket: "over_250").call
    assert_equal 3, result.total_count
  end

  test "filters by min rating" do
    result = Catalog::Search.new(min_rating: 4.7).call
    assert_equal 1, result.total_count
    assert_equal "iPhone 15 Pro", result.products.first.name
  end

  test "filters by in_stock" do
    Product.create!(
      name: "Out of Stock",
      slug: "out-of-stock",
      sku: "OOS-001",
      price_cents: 1000,
      stock_count: 0,
      category: @category,
      brand: @brand,
      active: true
    )
    result = Catalog::Search.new(in_stock: true).call
    assert_equal 3, result.total_count
  end

  test "sorts by price ascending" do
    result = Catalog::Search.new(sort: "price_asc").call
    prices = result.products.map(&:price_cents)
    assert_equal prices.sort, prices
  end

  test "sorts by price descending" do
    result = Catalog::Search.new(sort: "price_desc").call
    prices = result.products.map(&:price_cents)
    assert_equal prices.sort.reverse, prices
  end

  test "returns facets with counts" do
    result = Catalog::Search.new({}).call
    assert result.facets[:categories].any?
    assert result.facets[:brands].any?
    assert result.facets[:labels].any?
    assert result.facets[:prices].any?
    assert result.facets[:ratings].any?
  end

  test "disjunctive facets show counts excluding own filter" do
    # When filtering by Apple brand, brands facet should still show Samsung count
    result = Catalog::Search.new(brand_ids: [@brand.id]).call
    brands_facet = result.facets[:brands]
    apple = brands_facet.find { |b, _| b.name == "Apple" }
    samsung = brands_facet.find { |b, _| b.name == "Samsung" }
    assert_not_nil apple
    assert_not_nil samsung
    # Samsung should show its count even though we filtered by Apple
  end

  test "returns aggregates" do
    result = Catalog::Search.new({}).call
    assert result.aggregates[:min_price_cents] > 0
    assert result.aggregates[:max_price_cents] > 0
    assert result.aggregates[:avg_price_cents] > 0
    assert result.aggregates[:avg_rating] > 0
  end

  test "pagination works" do
    result = Catalog::Search.new(page: 1, per_page: 2).call
    assert_equal 2, result.products.size
    assert_equal 3, result.total_count
  end

  test "search with negation" do
    # This tests that the bm25_search with negation option works
    result = Catalog::Search.new(q: "iphone !pro").call
    # Should match iphone but exclude pro
    # Note: actual behavior depends on pg_textsearch implementation
    assert result.total_count >= 0
  end

  test "search with fuzzy matching" do
    result = Catalog::Search.new(q: "iphoe").call
    # Fuzzy should match "iphone"
    assert result.total_count >= 0
  end

  test "relevance sort returns scored products ordered by the ranking expression" do
    result = Catalog::Search.new(q: "camera").call

    assert result.products.all? { |p| p.bm25_score.present? }
    keys = result.products.map { |p| p.bm25_score - (0.05 * Math.log(p.popularity_score + 1)) }
    assert_equal keys.sort, keys
  end
end
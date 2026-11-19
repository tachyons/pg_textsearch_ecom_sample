# pg_textsearch E-commerce Sample

A small storefront built to show what [`pg_textsearch`](https://github.com/timescale/pg_textsearch) BM25 search feels like inside a real Rails app — ranked results, highlighted matches, prefix autocomplete and faceted filters, all powered by PostgreSQL.

![Demo](output.gif)

## Stack

- Ruby 4.0.2 / Rails 8.1 (Hotwire: Turbo + Stimulus)
- PostgreSQL 17 + [`pg_textsearch`](https://github.com/timescale/pg_textsearch) 1.5.1
- [`pg_textsearch` gem](https://github.com/tachyons/pg_textsearch) 0.1.6 (`has_bm25`, `bm25_search`, `bm25_match`)
- Tailwind CSS 4, Propshaft, Solid Queue / Solid Cache / Solid Cable

## Features

- **BM25 relevance search** over a combined `search_text` column (name, description, brand, category, labels), with title matches ranked via `ranked_by`
- **Prefix search / autocomplete** (`iph` → iPhone 15 Pro), powered by `@@ to_tsquery` prefix filters with `<@>` ordering
- **Highlighted snippets** (`ts_headline`) on result cards
- **Disjunctive faceted filtering** — category, brand, label, price bucket, rating and stock; each facet shows counts as if its own filter were removed
- **Sorting** by relevance, price, rating, newest or popularity
- **Cart** with Turbo Stream updates and a live header badge
- **Background jobs** — search logging, product reindexing and BM25 index compaction (Solid Queue)

## Requirements

1. PostgreSQL 17 or 18
2. The `pg_textsearch` extension installed and preloaded:

   ```conf
   # postgresql.conf
   shared_preload_libraries = 'pg_textsearch'
   ```

   Prebuilt packages are on the [releases page](https://github.com/timescale/pg_textsearch/releases); to build from source:

   ```sh
   git clone https://github.com/timescale/pg_textsearch
   cd pg_textsearch && make && sudo make install
   ```

3. Restart PostgreSQL after changing `shared_preload_libraries`.

## Setup

```sh
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/dev
```

Then open http://localhost:3000.

The seed file creates a small catalog (35 products, 26 categories, 34 brands, 12 labels) so search and facets have something to chew on. BM25 indexes are created by the migrations, not by the seeds.

## How the search is wired

`Catalog::Search` (`app/services/catalog/search.rb`) does the work:

- `matched_scope` — BM25 matching for 3+ character queries via `Product.bm25_match(:search_text, …, prefix: true)` (prefix expansion runs through `@@ to_tsquery`); 1–2 character queries fall back to `ILIKE` because English text search drops them as stop words
- `apply_filters` — category / brand / label / price / rating / stock conditions, with `exclude:` so facet counts stay disjunctive
- `apply_sorting` — `select_score: true, filter: false` to rank and highlight (`<mark>`) the already-filtered rows without adding a second `WHERE`; relevance uses

  ```sql
  bm25_score - 0.05 * ln(popularity_score + 1)
  ```

  with `rating_avg` as the tiebreaker

The model declares the indexes once (`app/models/product.rb`):

```ruby
has_bm25 :search_text, index: :products_active_search_idx, unaccent: true, prefix: true
has_bm25 :name,        index: :products_active_name_idx,  unaccent: true, prefix: true
has_bm25 :description, index: :products_active_desc_idx
```

`search_text` is denormalized on save and refreshed when labels change. The BM25 indexes are partial (`WHERE active`), so only live products are searchable.

## Tests

```sh
bin/rails db:test:prepare test
```

The suite covers search filtering, prefix matching, facet counts, sorting, pagination and relative ordering. CI runs the same command against PostgreSQL 17 with the extension installed (see `.github/workflows/ci.yml`).

## CI

GitHub Actions runs Brakeman, bundler-audit, `importmap audit`, RuboCop, and the test suite on `ubuntu-24.04`. The test job installs PostgreSQL 17 from the PGDG repository and the prebuilt `pg_textsearch` package, enables it via `shared_preload_libraries`, and then runs the migrations plus tests.

## Notes

- Search filters use `ILIKE` only for 1–2 character queries; everything else is BM25.
- BM25 prefix filtering requires `pg_textsearch` gem 0.1.5+; the app tracks the gem closely.
- `pg_textsearch` issues found while building this app are filed under [`tachyons/pg_textsearch`](https://github.com/tachyons/pg_textsearch/issues).

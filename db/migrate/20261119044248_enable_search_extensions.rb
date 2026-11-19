class EnableSearchExtensions < ActiveRecord::Migration[8.0]
  def up
    enable_extension "pg_textsearch"
    PgTextsearch::Maintenance.enable_unaccent!
    PgTextsearch::Maintenance.enable_pg_trgm!
  end

  def down
    disable_extension "pg_textsearch"
  end
end

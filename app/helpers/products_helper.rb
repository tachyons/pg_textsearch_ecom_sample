module ProductsHelper
  def any_filters_active?
    fp = search_params
    Array(fp[:category_ids]).any? || Array(fp[:brand_ids]).any? || Array(fp[:label_ids]).any? ||
      fp[:price_bucket].present? || fp[:min_price].present? || fp[:max_price].present? ||
      fp[:min_rating].present? || ActiveModel::Type::Boolean.new.cast(fp[:in_stock])
  end

  def filter_params
    @filter_params ||= search_params
  end

  def label_badge_class(color)
    case color.to_s
    when "amber"   then "bg-amber-50 text-amber-700 border-amber-200"
    when "green"   then "bg-emerald-50 text-emerald-700 border-emerald-200"
    when "emerald" then "bg-emerald-50 text-emerald-700 border-emerald-200"
    when "red"     then "bg-rose-50 text-rose-700 border-rose-200"
    when "purple"  then "bg-purple-50 text-purple-700 border-purple-200"
    when "orange"  then "bg-orange-50 text-orange-700 border-orange-200"
    when "indigo"  then "bg-indigo-50 text-indigo-700 border-indigo-200"
    when "blue"    then "bg-sky-50 text-sky-700 border-sky-200"
    when "pink"    then "bg-pink-50 text-pink-700 border-pink-200"
    when "rose"    then "bg-rose-50 text-rose-700 border-rose-200"
    when "teal"    then "bg-teal-50 text-teal-700 border-teal-200"
    when "violet"  then "bg-violet-50 text-violet-700 border-violet-200"
    else                "bg-slate-50 text-slate-700 border-slate-200"
    end
  end

  def render_active_filter_chips(form)
    fp = filter_params
    chips = []

    Array(fp[:category_ids]).each do |id|
      cat = Category.find_by(id: id)
      next unless cat
      chips << active_filter_chip(cat.name, "category_ids", id, category_ids: Array(fp[:category_ids]) - [ id ])
    end

    Array(fp[:brand_ids]).each do |id|
      brand = Brand.find_by(id: id)
      next unless brand
      chips << active_filter_chip(brand.name, "brand_ids", id, brand_ids: Array(fp[:brand_ids]) - [ id ])
    end

    Array(fp[:label_ids]).each do |id|
      label = Label.find_by(id: id)
      next unless label
      chips << active_filter_chip(label.name, "label_ids", id, label_ids: Array(fp[:label_ids]) - [ id ])
    end

    if fp[:price_bucket].present?
      bucket = Catalog::Search::PRICE_BUCKETS.find { |b| b[:key] == fp[:price_bucket] }
      chips << active_filter_chip(bucket[:label], "price_bucket", fp[:price_bucket], price_bucket: nil) if bucket
    end

    if fp[:min_price].present? || fp[:max_price].present?
      range = "$#{fp[:min_price] || 0} – $#{fp[:max_price] || '∞'}"
      chips << active_filter_chip(range, "price_range", 1, min_price: nil, max_price: nil)
    end

    if fp[:min_rating].present?
      chips << active_filter_chip("★ #{fp[:min_rating]}+", "min_rating", fp[:min_rating], min_rating: nil)
    end

    if ActiveModel::Type::Boolean.new.cast(fp[:in_stock])
      chips << active_filter_chip("In Stock", "in_stock", 1, in_stock: false)
    end

    safe_join(chips, " ")
  end

  def active_filter_chip(label, param_key, value, remove_params)
    params = search_params.to_h.merge(remove_params)
    link_to products_path(params),
      data: { turbo_frame: "catalog", turbo_action: "advance" },
      class: "group inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-medium bg-slate-100 hover:bg-rose-50 text-slate-700 hover:text-rose-700 rounded-full border border-slate-200/80 hover:border-rose-200 transition-colors" do
      concat tag.span(label)
      concat tag.svg(
        tag.path(d: "M6 18L18 6M6 6l12 12", stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2"),
        viewBox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        class: "w-3 h-3 text-slate-400 group-hover:text-rose-600 transition-colors"
      )
    end
  end

  def render_facet_section(form, param_name, title, facets)
    return "".html_safe if facets.blank?

    fp = filter_params
    selected_ids = Array(fp[param_name]).map(&:to_i)

    tag.div(class: "space-y-2.5") do
      concat tag.h3(title, class: "text-xs font-semibold uppercase tracking-wider text-slate-500")
      concat(tag.div(class: "space-y-1.5 max-h-56 overflow-y-auto pr-1") do
        safe_join(
          facets.map do |record, count|
            next if count.zero?
            checked = selected_ids.include?(record.id)
            tag.label(class: "flex items-center justify-between gap-2.5 px-2 py-1.5 rounded-lg cursor-pointer hover:bg-slate-50 transition-colors #{checked ? 'bg-indigo-50/70 text-indigo-900 font-medium' : 'text-slate-700'}") do
              concat(tag.span(class: "flex items-center gap-2.5 min-w-0") do
                concat form.check_box(param_name, {
                  multiple: true,
                  checked: checked,
                  class: "w-4 h-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500 focus:ring-offset-0 transition cursor-pointer",
                  data: { action: "change->catalog-form#submit" }
                }, record.id, nil)
                concat tag.span(record.name, class: "text-sm truncate select-none")
              end)
              concat tag.span(count, class: "text-xs tabular-nums px-2 py-0.5 rounded-full #{checked ? 'bg-indigo-100 text-indigo-700 font-semibold' : 'bg-slate-100 text-slate-500'}")
            end
          end.compact
        )
      end)
    end
  end

  def render_price_facet_section(form)
    fp = filter_params

    tag.div(class: "border-t border-slate-200/80 pt-4 space-y-3") do
      concat tag.h3("Price", class: "text-xs font-semibold uppercase tracking-wider text-slate-500")
      concat(tag.div(class: "space-y-1.5") do
        safe_join(
          Catalog::Search::PRICE_BUCKETS.map do |bucket|
            count = @result.facets[:prices].find { |b| b[:key] == bucket[:key] }&.fetch(:count, 0) || 0
            next if count.zero?

            checked = fp[:price_bucket] == bucket[:key]
            tag.label(class: "flex items-center justify-between gap-2.5 px-2 py-1.5 rounded-lg cursor-pointer hover:bg-slate-50 transition-colors #{checked ? 'bg-indigo-50/70 text-indigo-900 font-medium' : 'text-slate-700'}") do
              concat(tag.span(class: "flex items-center gap-2.5") do
                concat form.radio_button(:price_bucket, bucket[:key],
                  checked: checked,
                  class: "w-4 h-4 text-indigo-600 border-slate-300 focus:ring-indigo-500 transition cursor-pointer",
                  data: { action: "change->catalog-form#submit" })
                concat tag.span(bucket[:label], class: "text-sm select-none")
              end)
              concat tag.span(count, class: "text-xs tabular-nums px-2 py-0.5 rounded-full #{checked ? 'bg-indigo-100 text-indigo-700 font-semibold' : 'bg-slate-100 text-slate-500'}")
            end
          end.compact + [
            tag.label(class: "flex items-center justify-between gap-2.5 px-2 py-1.5 rounded-lg cursor-pointer hover:bg-slate-50 transition-colors #{fp[:price_bucket].blank? ? 'bg-indigo-50/70 text-indigo-900 font-medium' : 'text-slate-700'}") do
              concat(tag.span(class: "flex items-center gap-2.5") do
                concat form.radio_button(:price_bucket, "",
                  checked: fp[:price_bucket].blank?,
                  class: "w-4 h-4 text-indigo-600 border-slate-300 focus:ring-indigo-500 transition cursor-pointer",
                  data: { action: "change->catalog-form#submit" })
                concat tag.span("All prices", class: "text-sm select-none")
              end)
            end
          ]
        )
      end)
    end
  end

  def render_rating_facet_section(form)
    fp = filter_params

    tag.div(class: "border-t border-slate-200/80 pt-4 space-y-3") do
      concat tag.h3("Rating", class: "text-xs font-semibold uppercase tracking-wider text-slate-500")
      concat(tag.div(class: "space-y-1.5") do
        safe_join(
          @result.facets[:ratings].map do |rating|
            next if rating[:count].zero?
            checked = @min_rating.to_f == rating[:stars].to_f
            tag.label(class: "flex items-center justify-between gap-2.5 px-2 py-1.5 rounded-lg cursor-pointer hover:bg-slate-50 transition-colors #{checked ? 'bg-indigo-50/70 text-indigo-900 font-medium' : 'text-slate-700'}") do
              concat(tag.span(class: "flex items-center gap-2 min-w-0") do
                concat form.radio_button(:min_rating, rating[:stars],
                  checked: checked,
                  class: "w-4 h-4 text-indigo-600 border-slate-300 focus:ring-indigo-500 transition cursor-pointer",
                  data: { action: "change->catalog-form#submit" })
                concat render_star_icons(rating[:stars])
                concat tag.span("#{rating[:stars]}+ stars", class: "text-sm select-none text-slate-700")
              end)
              concat tag.span(rating[:count], class: "text-xs tabular-nums px-2 py-0.5 rounded-full #{checked ? 'bg-indigo-100 text-indigo-700 font-semibold' : 'bg-slate-100 text-slate-500'}")
            end
          end.compact + [
            tag.label(class: "flex items-center justify-between gap-2.5 px-2 py-1.5 rounded-lg cursor-pointer hover:bg-slate-50 transition-colors #{@min_rating.blank? ? 'bg-indigo-50/70 text-indigo-900 font-medium' : 'text-slate-700'}") do
              concat(tag.span(class: "flex items-center gap-2") do
                concat form.radio_button(:min_rating, "",
                  checked: @min_rating.blank?,
                  class: "w-4 h-4 text-indigo-600 border-slate-300 focus:ring-indigo-500 transition cursor-pointer",
                  data: { action: "change->catalog-form#submit" })
                concat tag.span("All ratings", class: "text-sm select-none")
              end)
            end
          ]
        )
      end)
    end
  end

  def render_star_icons(stars)
    tag.span(class: "inline-flex items-center gap-0.5 text-amber-400") do
      5.times.map do |i|
        fill_color = i < stars.to_i ? "currentColor" : "#e2e8f0"
        tag.svg(
          tag.path(d: "M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"),
          viewBox: "0 0 20 20",
          fill: fill_color,
          class: "w-3.5 h-3.5 flex-shrink-0"
        )
      end.join.html_safe
    end
  end

  def render_rating_badge(rating, count = nil)
    return "".html_safe if rating.to_f.zero?

    tag.div(class: "inline-flex items-center gap-1.5 text-xs") do
      concat tag.svg(
        tag.path(d: "M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"),
        viewBox: "0 0 20 20",
        fill: "currentColor",
        class: "w-3.5 h-3.5 text-amber-400 flex-shrink-0"
      )
      concat tag.span(number_with_precision(rating, precision: 1), class: "font-semibold text-slate-800")
      concat tag.span("(#{count || rating_count_estimate(rating)})", class: "text-slate-400")
    end
  end

  def rating_count_estimate(rating)
    # Natural deterministic review count based on rating
    ((rating * 29).round + 12)
  end

  # Category-specific SVG vector visuals for modern product displays
  def product_visual(product, size: :card)
    category_slug = product.category&.slug.to_s
    parent_slug = product.category&.parent&.slug.to_s
    name_down = product.name.downcase

    # Dimensions and container classes
    container_class = case size
    when :thumb
                        "w-12 h-12 rounded-lg"
    when :card
                        "w-full aspect-[4/3] rounded-xl"
    when :hero
                        "w-full aspect-square rounded-2xl"
    else
                        "w-full aspect-[4/3] rounded-xl"
    end

    svg_content = if category_slug.include?("smartphone") || name_down.include?("iphone") || name_down.include?("galaxy s") || name_down.include?("pixel")
                    smartphone_svg(size)
    elsif category_slug.include?("laptop") || name_down.include?("macbook") || name_down.include?("thinkpad") || name_down.include?("xps") || name_down.include?("zephyrus")
                    laptop_svg(size)
    elsif category_slug.include?("headphone") || name_down.include?("wh-1000") || name_down.include?("airpods") || name_down.include?("quietcomfort") || name_down.include?("momentum")
                    headphones_svg(size)
    elsif category_slug.include?("camera") || name_down.include?("eos") || name_down.include?("nikon") || name_down.include?("gopro") || name_down.include?("fujifilm")
                    camera_svg(size)
    elsif category_slug.include?("watch") || name_down.include?("watch") || name_down.include?("forerunner")
                    smartwatch_svg(size)
    elsif category_slug.include?("shoe") || name_down.include?("sneaker") || name_down.include?("ultraboost") || name_down.include?("cloud")
                    shoe_svg(size)
    elsif category_slug.include?("clothing") || name_down.include?("hoodie") || name_down.include?("jacket") || name_down.include?("tee") || name_down.include?("jeans")
                    clothing_svg(size)
    elsif category_slug.include?("furniture") || name_down.include?("chair") || name_down.include?("sofa") || name_down.include?("shelf")
                    furniture_svg(size)
    elsif category_slug.include?("kitchen") || name_down.include?("mixer") || name_down.include?("espresso")
                    kitchen_svg(size)
    elsif category_slug.include?("fitness") || name_down.include?("bike") || name_down.include?("dumbbell")
                    fitness_svg(size)
    elsif category_slug.include?("camping") || name_down.include?("tent") || name_down.include?("tumbler")
                    camping_svg(size)
    elsif parent_slug.include?("book") || category_slug.include?("fiction") || category_slug.include?("book")
                    book_svg(size)
    else
                    generic_product_svg(size)
    end

    tag.div(class: "#{container_class} bg-gradient-to-br from-slate-100 via-slate-50 to-indigo-50/40 border border-slate-200/60 flex items-center justify-center p-4 relative overflow-hidden group-hover:scale-[1.02] transition-transform duration-300") do
      svg_content.html_safe
    end
  end

  private

  def smartphone_svg(size)
    scale = size == :hero ? "w-48 h-48" : (size == :thumb ? "w-8 h-8" : "w-28 h-28")
    <<-SVG
      <svg class="#{scale} text-slate-800 drop-shadow-md transition-transform group-hover:scale-105 duration-300" viewBox="0 0 100 120" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect x="25" y="10" width="50" height="100" rx="10" fill="#1e293b" stroke="#334155" stroke-width="2"/>
        <rect x="28" y="14" width="44" height="92" rx="7" fill="url(#phone-grad)"/>
        <path d="M44 16H56V18C56 19.1046 55.1046 20 54 20H46C44.8954 20 44 19.1046 44 18V16Z" fill="#0f172a"/>
        <circle cx="50" cy="18" r="1.5" fill="#38bdf8"/>
        <!-- Screen artwork -->
        <circle cx="50" cy="55" r="16" fill="url(#orb-grad)" opacity="0.8"/>
        <path d="M36 88H64" stroke="#ffffff" stroke-width="1.5" stroke-linecap="round" opacity="0.6"/>
        <defs>
          <linearGradient id="phone-grad" x1="28" y1="14" x2="72" y2="106" gradientUnits="userSpaceOnUse">
            <stop stop-color="#0f172a"/>
            <stop offset="0.5" stop-color="#1e1b4b"/>
            <stop offset="1" stop-color="#312e81"/>
          </linearGradient>
          <linearGradient id="orb-grad" x1="34" y1="39" x2="66" y2="71" gradientUnits="userSpaceOnUse">
            <stop stop-color="#38bdf8"/>
            <stop offset="1" stop-color="#818cf8"/>
          </linearGradient>
        </defs>
      </svg>
    SVG
  end

  def laptop_svg(size)
    scale = size == :hero ? "w-56 h-56" : (size == :thumb ? "w-8 h-8" : "w-32 h-32")
    <<-SVG
      <svg class="#{scale} text-slate-800 drop-shadow-md transition-transform group-hover:scale-105 duration-300" viewBox="0 0 120 100" fill="none" xmlns="http://www.w3.org/2000/svg">
        <!-- Display lid -->
        <rect x="22" y="18" width="76" height="52" rx="5" fill="#1e293b" stroke="#475569" stroke-width="2"/>
        <rect x="26" y="22" width="68" height="44" rx="2" fill="url(#lap-grad)"/>
        <!-- Notch/camera -->
        <circle cx="60" cy="20" r="1" fill="#38bdf8"/>
        <!-- Base / Keyboard -->
        <path d="M12 73C12 71.3431 13.3431 70 15 70H105C106.657 70 108 71.3431 108 73L114 82C114 83.6569 112.657 85 111 85H9C7.34315 85 6 83.6569 6 82L12 73Z" fill="#334155"/>
        <path d="M50 71H70V73H50V71Z" fill="#64748b" rx="1"/>
        <defs>
          <linearGradient id="lap-grad" x1="26" y1="22" x2="94" y2="66" gradientUnits="userSpaceOnUse">
            <stop stop-color="#0284c7"/>
            <stop offset="0.6" stop-color="#4f46e5"/>
            <stop offset="1" stop-color="#7c3aed"/>
          </linearGradient>
        </defs>
      </svg>
    SVG
  end

  def headphones_svg(size)
    scale = size == :hero ? "w-48 h-48" : (size == :thumb ? "w-8 h-8" : "w-28 h-28")
    <<-SVG
      <svg class="#{scale} text-slate-800 drop-shadow-md transition-transform group-hover:scale-105 duration-300" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
        <!-- Headband -->
        <path d="M22 55C22 36.7746 34.536 22 50 22C65.464 22 78 36.7746 78 55" stroke="#1e293b" stroke-width="7" stroke-linecap="round"/>
        <path d="M30 38C35 28 42 25 50 25C58 25 65 28 70 38" stroke="#475569" stroke-width="3" stroke-linecap="round"/>
        <!-- Left Ear cup -->
        <rect x="14" y="50" width="16" height="30" rx="8" fill="#334155" stroke="#1e293b" stroke-width="2"/>
        <rect x="18" y="54" width="8" height="22" rx="4" fill="#6366f1"/>
        <!-- Right Ear cup -->
        <rect x="70" y="50" width="16" height="30" rx="8" fill="#334155" stroke="#1e293b" stroke-width="2"/>
        <rect x="74" y="54" width="8" height="22" rx="4" fill="#6366f1"/>
      </svg>
    SVG
  end

  def camera_svg(size)
    scale = size == :hero ? "w-48 h-48" : (size == :thumb ? "w-8 h-8" : "w-28 h-28")
    <<-SVG
      <svg class="#{scale} text-slate-800 drop-shadow-md transition-transform group-hover:scale-105 duration-300" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect x="15" y="32" width="70" height="48" rx="8" fill="#1e293b" stroke="#334155" stroke-width="2"/>
        <!-- Top dials & viewfinder -->
        <rect x="36" y="24" width="28" height="10" rx="3" fill="#334155"/>
        <rect x="70" y="26" width="10" height="6" rx="2" fill="#64748b"/>
        <circle cx="26" cy="27" r="3" fill="#f43f5e"/>
        <!-- Lens ring -->
        <circle cx="50" cy="56" r="20" fill="#0f172a" stroke="#475569" stroke-width="3"/>
        <circle cx="50" cy="56" r="14" fill="url(#lens-grad)"/>
        <circle cx="46" cy="52" r="4" fill="#ffffff" opacity="0.5"/>
        <defs>
          <linearGradient id="lens-grad" x1="36" y1="42" x2="64" y2="70" gradientUnits="userSpaceOnUse">
            <stop stop-color="#0284c7"/>
            <stop offset="1" stop-color="#0f172a"/>
          </linearGradient>
        </defs>
      </svg>
    SVG
  end

  def smartwatch_svg(size)
    scale = size == :hero ? "w-48 h-48" : (size == :thumb ? "w-8 h-8" : "w-28 h-28")
    <<-SVG
      <svg class="#{scale} text-slate-800 drop-shadow-md transition-transform group-hover:scale-105 duration-300" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
        <!-- Straps -->
        <rect x="38" y="10" width="24" height="24" rx="4" fill="#475569"/>
        <rect x="38" y="66" width="24" height="24" rx="4" fill="#475569"/>
        <!-- Body -->
        <rect x="30" y="26" width="40" height="48" rx="12" fill="#0f172a" stroke="#334155" stroke-width="2"/>
        <rect x="34" y="30" width="32" height="40" rx="8" fill="url(#watch-grad)"/>
        <!-- Crown button -->
        <rect x="71" y="38" width="3" height="8" rx="1.5" fill="#94a3b8"/>
        <!-- Activity Rings -->
        <circle cx="50" cy="50" r="10" stroke="#f43f5e" stroke-width="2.5" fill="none"/>
        <circle cx="50" cy="50" r="6" stroke="#10b981" stroke-width="2" fill="none"/>
        <defs>
          <linearGradient id="watch-grad" x1="34" y1="30" x2="66" y2="70" gradientUnits="userSpaceOnUse">
            <stop stop-color="#020617"/>
            <stop offset="1" stop-color="#1e1b4b"/>
          </linearGradient>
        </defs>
      </svg>
    SVG
  end

  def shoe_svg(size)
    scale = size == :hero ? "w-48 h-48" : (size == :thumb ? "w-8 h-8" : "w-28 h-28")
    <<-SVG
      <svg class="#{scale} text-slate-800 drop-shadow-md transition-transform group-hover:scale-105 duration-300" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M14 62C14 55 22 52 30 52C34 52 40 40 50 36C56 34 64 36 68 44L84 56C88 59 90 62 88 66L84 72H16L14 62Z" fill="#2563eb"/>
        <path d="M12 72H88V77C88 80 85 82 81 82H19C15 82 12 80 12 77V72Z" fill="#f8fafc" stroke="#cbd5e1" stroke-width="1.5"/>
        <path d="M38 52L46 44M44 54L52 46M50 56L58 48" stroke="#ffffff" stroke-width="2" stroke-linecap="round"/>
        <path d="M34 64C48 64 62 58 74 52" stroke="#ffffff" stroke-width="3" stroke-linecap="round"/>
      </svg>
    SVG
  end

  def clothing_svg(size)
    scale = size == :hero ? "w-48 h-48" : (size == :thumb ? "w-8 h-8" : "w-28 h-28")
    <<-SVG
      <svg class="#{scale} text-slate-800 drop-shadow-md transition-transform group-hover:scale-105 duration-300" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M36 20C42 24 58 24 64 20L84 32L74 46L66 40V82H34V40L26 46L16 32L36 20Z" fill="#3b82f6" stroke="#1d4ed8" stroke-width="2" stroke-linejoin="round"/>
        <path d="M42 22C46 26 54 26 58 22" stroke="#1d4ed8" stroke-width="2" stroke-linecap="round"/>
        <path d="M50 40V82" stroke="#1d4ed8" stroke-width="1.5" stroke-dasharray="2 2"/>
      </svg>
    SVG
  end

  def furniture_svg(size)
    scale = size == :hero ? "w-48 h-48" : (size == :thumb ? "w-8 h-8" : "w-28 h-28")
    <<-SVG
      <svg class="#{scale} text-slate-800 drop-shadow-md transition-transform group-hover:scale-105 duration-300" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
        <!-- Backrest -->
        <rect x="32" y="22" width="36" height="38" rx="8" fill="#d97706" stroke="#92400e" stroke-width="2"/>
        <!-- Seat -->
        <path d="M24 58C24 54 28 52 32 52H68C72 52 76 54 76 58L72 68H28L24 58Z" fill="#b45309"/>
        <!-- Legs -->
        <path d="M30 68L22 84M70 68L78 84M40 68L38 82M60 68L62 82" stroke="#451a03" stroke-width="3" stroke-linecap="round"/>
      </svg>
    SVG
  end

  def kitchen_svg(size)
    scale = size == :hero ? "w-48 h-48" : (size == :thumb ? "w-8 h-8" : "w-28 h-28")
    <<-SVG
      <svg class="#{scale} text-slate-800 drop-shadow-md transition-transform group-hover:scale-105 duration-300" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect x="25" y="24" width="50" height="54" rx="6" fill="#e2e8f0" stroke="#64748b" stroke-width="2"/>
        <rect x="30" y="30" width="40" height="12" rx="3" fill="#1e293b"/>
        <circle cx="36" cy="36" r="2" fill="#10b981"/>
        <circle cx="44" cy="36" r="2" fill="#38bdf8"/>
        <!-- Portafilter / Spout -->
        <rect x="42" y="46" width="16" height="14" rx="2" fill="#64748b"/>
        <rect x="32" y="50" width="10" height="4" rx="1" fill="#334155"/>
        <!-- Drip tray -->
        <rect x="20" y="78" width="60" height="8" rx="3" fill="#94a3b8"/>
      </svg>
    SVG
  end

  def fitness_svg(size)
    scale = size == :hero ? "w-48 h-48" : (size == :thumb ? "w-8 h-8" : "w-28 h-28")
    <<-SVG
      <svg class="#{scale} text-slate-800 drop-shadow-md transition-transform group-hover:scale-105 duration-300" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect x="46" y="25" width="8" height="50" rx="3" fill="#94a3b8" stroke="#475569" stroke-width="1.5"/>
        <rect x="24" y="32" width="22" height="36" rx="4" fill="#1e293b"/>
        <rect x="54" y="32" width="22" height="36" rx="4" fill="#1e293b"/>
        <rect x="18" y="38" width="6" height="24" rx="2" fill="#0284c7"/>
        <rect x="76" y="38" width="6" height="24" rx="2" fill="#0284c7"/>
      </svg>
    SVG
  end

  def camping_svg(size)
    scale = size == :hero ? "w-48 h-48" : (size == :thumb ? "w-8 h-8" : "w-28 h-28")
    <<-SVG
      <svg class="#{scale} text-slate-800 drop-shadow-md transition-transform group-hover:scale-105 duration-300" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M14 74L48 24C49 22 51 22 52 24L86 74C88 77 86 80 82 80H18C14 80 12 77 14 74Z" fill="#047857" stroke="#065f46" stroke-width="2"/>
        <path d="M50 24V80" stroke="#064e3b" stroke-width="2"/>
        <path d="M50 54L34 80H66L50 54Z" fill="#fbbf24"/>
      </svg>
    SVG
  end

  def book_svg(size)
    scale = size == :hero ? "w-48 h-48" : (size == :thumb ? "w-8 h-8" : "w-28 h-28")
    <<-SVG
      <svg class="#{scale} text-slate-800 drop-shadow-md transition-transform group-hover:scale-105 duration-300" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect x="28" y="16" width="46" height="68" rx="4" fill="#7c3aed" stroke="#5b21b6" stroke-width="2"/>
        <rect x="24" y="16" width="6" height="68" rx="2" fill="#4c1d95"/>
        <path d="M38 32H64M38 42H58M38 52H62" stroke="#e9d5ff" stroke-width="2" stroke-linecap="round"/>
        <!-- Ribbon bookmark -->
        <path d="M52 16V30L56 26L60 30V16H52Z" fill="#f43f5e"/>
      </svg>
    SVG
  end

  def generic_product_svg(size)
    scale = size == :hero ? "w-48 h-48" : (size == :thumb ? "w-8 h-8" : "w-28 h-28")
    <<-SVG
      <svg class="#{scale} text-slate-800 drop-shadow-md transition-transform group-hover:scale-105 duration-300" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M50 18L82 34V66L50 82L18 66V34L50 18Z" fill="#4f46e5" stroke="#3730a3" stroke-width="2" stroke-linejoin="round"/>
        <path d="M50 18V82" stroke="#3730a3" stroke-width="1.5"/>
        <path d="M18 34L50 50L82 34" stroke="#3730a3" stroke-width="1.5"/>
      </svg>
    SVG
  end

  def search_params
    params.permit(:q, :sort, :page, :price_bucket, :min_price, :max_price, :min_rating, :in_stock,
                  category_ids: [], brand_ids: [], label_ids: [])
  end
end

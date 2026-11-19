# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Categories
categories = {
  "Electronics" => {
    slug: "electronics",
    children: {
      "Smartphones" => { slug: "smartphones" },
      "Laptops" => { slug: "laptops" },
      "Headphones" => { slug: "headphones" },
      "Cameras" => { slug: "cameras" },
      "Smart Watches" => { slug: "smart-watches" }
    }
  },
  "Clothing" => {
    slug: "clothing",
    children: {
      "Men's Clothing" => { slug: "mens-clothing" },
      "Women's Clothing" => { slug: "womens-clothing" },
      "Shoes" => { slug: "shoes" },
      "Accessories" => { slug: "accessories" }
    }
  },
  "Home & Garden" => {
    slug: "home-garden",
    children: {
      "Furniture" => { slug: "furniture" },
      "Kitchen" => { slug: "kitchen" },
      "Decor" => { slug: "decor" },
      "Garden" => { slug: "garden" }
    }
  },
  "Sports & Outdoors" => {
    slug: "sports-outdoors",
    children: {
      "Fitness" => { slug: "fitness" },
      "Camping" => { slug: "camping" },
      "Cycling" => { slug: "cycling" },
      "Water Sports" => { slug: "water-sports" }
    }
  },
  "Books" => {
    slug: "books",
    children: {
      "Fiction" => { slug: "fiction" },
      "Non-Fiction" => { slug: "non-fiction" },
      "Children's Books" => { slug: "childrens-books" },
      "Textbooks" => { slug: "textbooks" }
    }
  }
}

category_records = {}
categories.each do |parent_name, parent_data|
  parent = Category.find_or_create_by!(slug: parent_data[:slug]) do |c|
    c.name = parent_name
  end
  category_records[parent_name] = parent

  parent_data[:children].each do |child_name, child_data|
    child = Category.find_or_create_by!(slug: child_data[:slug]) do |c|
      c.name = child_name
      c.parent = parent
    end
    category_records["#{parent_name} > #{child_name}"] = child
  end
end

# Brands
brand_names = [
  "Apple", "Samsung", "Sony", "LG", "Dell", "HP", "Lenovo", "ASUS",
  "Nike", "Adidas", "Puma", "Under Armour", "The North Face", "Patagonia",
  "IKEA", "Herman Miller", "West Elm", "Crate & Barrel",
  "Canon", "Nikon", "Fujifilm", "GoPro",
  "Bose", "Sennheiser", "Audio-Technica", "JBL",
  "Garmin", "Fitbit", "Polar", "Suunto",
  "Penguin Random House", "HarperCollins", "Simon & Schuster", "Macmillan"
]

brand_records = {}
brand_names.each do |name|
  brand_records[name] = Brand.find_or_create_by!(slug: name.parameterize) do |b|
    b.name = name
  end
end

# Labels
labels = [
  { name: "Bestseller", slug: "bestseller", color: "amber" },
  { name: "New Arrival", slug: "new-arrival", color: "green" },
  { name: "Eco-Friendly", slug: "eco-friendly", color: "emerald" },
  { name: "Clearance", slug: "clearance", color: "red" },
  { name: "Limited Edition", slug: "limited-edition", color: "purple" },
  { name: "Sale", slug: "sale", color: "orange" },
  { name: "Premium", slug: "premium", color: "indigo" },
  { name: "Budget Pick", slug: "budget-pick", color: "blue" },
  { name: "Staff Favorite", slug: "staff-favorite", color: "pink" },
  { name: "Trending", slug: "trending", color: "rose" },
  { name: "Exclusive", slug: "exclusive", color: "violet" },
  { name: "Back in Stock", slug: "back-in-stock", color: "teal" }
]

label_records = {}
labels.each do |label|
  label_records[label[:name]] = Label.find_or_create_by!(slug: label[:slug]) do |l|
    l.name = label[:name]
    l.color = label[:color]
  end
end

# Products
require "securerandom"

def random_sku(prefix)
  "#{prefix}-#{SecureRandom.alphanumeric(8).upcase}"
end

product_data = [
  # Electronics > Smartphones
  { name: "iPhone 15 Pro", category: "Electronics > Smartphones", brand: "Apple", price: 99900, stock: 50, rating: 4.8, popularity: 9500, desc: "Latest iPhone with A17 Pro chip, titanium design, and advanced camera system." },
  { name: "iPhone 15", category: "Electronics > Smartphones", brand: "Apple", price: 79900, stock: 75, rating: 4.6, popularity: 8800, desc: "Dynamic Island, 48MP main camera, USB-C, and A16 Bionic chip." },
  { name: "Galaxy S24 Ultra", category: "Electronics > Smartphones", brand: "Samsung", price: 129900, stock: 40, rating: 4.7, popularity: 9200, desc: "Galaxy AI, 200MP camera, S Pen, and Snapdragon 8 Gen 3." },
  { name: "Galaxy S24", category: "Electronics > Smartphones", brand: "Samsung", price: 79900, stock: 60, rating: 4.5, popularity: 7800, desc: "Compact flagship with Galaxy AI and 50MP camera." },
  { name: "Pixel 8 Pro", category: "Electronics > Smartphones", brand: "Google", price: 99900, stock: 35, rating: 4.6, popularity: 7500, desc: "Google AI, best Android camera, 7 years of updates." },
  { name: "Pixel 8a", category: "Electronics > Smartphones", brand: "Google", price: 49900, stock: 80, rating: 4.4, popularity: 6800, desc: "Affordable Pixel with Tensor G3 and great camera." },

  # Electronics > Laptops
  { name: "MacBook Pro 16 M3 Max", category: "Electronics > Laptops", brand: "Apple", price: 349900, stock: 15, rating: 4.9, popularity: 8500, desc: "Most powerful Mac laptop for pro workflows." },
  { name: "MacBook Air 15 M3", category: "Electronics > Laptops", brand: "Apple", price: 129900, stock: 45, rating: 4.8, popularity: 9100, desc: "Thin, light, and powerful with 18-hour battery." },
  { name: "XPS 15", category: "Electronics > Laptops", brand: "Dell", price: 189900, stock: 25, rating: 4.5, popularity: 7200, desc: "Premium Windows laptop with OLED display." },
  { name: "ThinkPad X1 Carbon Gen 12", category: "Electronics > Laptops", brand: "Lenovo", price: 169900, stock: 30, rating: 4.6, popularity: 7000, desc: "Ultra-light business laptop with Intel Core Ultra." },
  { name: "ROG Zephyrus G14", category: "Electronics > Laptops", brand: "ASUS", price: 159900, stock: 20, rating: 4.7, popularity: 7800, desc: "Compact gaming laptop with RTX 4070." },
  { name: "Spectre x360 14", category: "Electronics > Laptops", brand: "HP", price: 139900, stock: 35, rating: 4.4, popularity: 6500, desc: "Versatile 2-in-1 with OLED touchscreen." },

  # Electronics > Headphones
  { name: "WH-1000XM5", category: "Electronics > Headphones", brand: "Sony", price: 39900, stock: 100, rating: 4.8, popularity: 9500, desc: "Industry-leading noise cancellation and 30-hour battery." },
  { name: "QC Ultra Headphones", category: "Electronics > Headphones", brand: "Bose", price: 42900, stock: 80, rating: 4.7, popularity: 8800, desc: "Best-in-class comfort and spatial audio." },
  { name: "AirPods Pro 2", category: "Electronics > Headphones", brand: "Apple", price: 24900, stock: 120, rating: 4.7, popularity: 9800, desc: "Adaptive Transparency, USB-C case, H2 chip." },
  { name: "Momentum 4 Wireless", category: "Electronics > Headphones", brand: "Sennheiser", price: 34900, stock: 60, rating: 4.6, popularity: 7200, desc: "Audiophile sound with 60-hour battery." },
  { name: "ATH-M50xBT2", category: "Electronics > Headphones", brand: "Audio-Technica", price: 19900, stock: 90, rating: 4.5, popularity: 7500, desc: "Legendary studio sound in wireless form." },

  # Electronics > Cameras
  { name: "EOS R5", category: "Electronics > Cameras", brand: "Canon", price: 389900, stock: 10, rating: 4.9, popularity: 7000, desc: "45MP full-frame mirrorless with 8K video." },
  { name: "Z9", category: "Electronics > Cameras", brand: "Nikon", price: 549900, stock: 8, rating: 4.9, popularity: 6800, desc: "Flagship full-frame stacked sensor, 8K/60p." },
  { name: "X-T5", category: "Electronics > Cameras", brand: "Fujifilm", price: 169900, stock: 25, rating: 4.8, popularity: 7500, desc: "40MP APS-C with film simulations." },
  { name: "HERO12 Black", category: "Electronics > Cameras", brand: "GoPro", price: 39900, stock: 80, rating: 4.5, popularity: 8200, desc: "5.3K60 action camera with HyperSmooth 6.0." },

  # Electronics > Smart Watches
  { name: "Apple Watch Ultra 2", category: "Electronics > Smart Watches", brand: "Apple", price: 79900, stock: 40, rating: 4.8, popularity: 8500, desc: "Rugged titanium, precision dual-frequency GPS." },
  { name: "Galaxy Watch 6 Classic", category: "Electronics > Smart Watches", brand: "Samsung", price: 39900, stock: 50, rating: 4.5, popularity: 7000, desc: "Rotating bezel, Wear OS, body composition." },
  { name: "Forerunner 965", category: "Electronics > Smart Watches", brand: "Garmin", price: 59900, stock: 30, rating: 4.8, popularity: 7200, desc: "AMOLED display, maps, 23-day battery." },
  { name: "Vantage V3", category: "Electronics > Smart Watches", brand: "Polar", price: 59900, stock: 25, rating: 4.6, popularity: 6500, desc: "AMOLED, biosensing, offline maps." },

  # Clothing > Men's
  { name: "Tech Fleece Hoodie", category: "Clothing > Men's Clothing", brand: "Nike", price: 13000, stock: 200, rating: 4.6, popularity: 8800, desc: "Lightweight warmth with modern fit." },
  { name: "Ultraboost 23", category: "Clothing > Shoes", brand: "Adidas", price: 19000, stock: 150, rating: 4.5, popularity: 9200, desc: "Responsive Boost midsole, Primeknit upper." },
  { name: "P-6 Logo Tee", category: "Clothing > Men's Clothing", brand: "Patagonia", price: 4500, stock: 300, rating: 4.7, popularity: 8000, desc: "Organic cotton, fair trade certified." },
  { name: "511 Slim Jeans", category: "Clothing > Men's Clothing", brand: "Levi's", price: 6999, stock: 250, rating: 4.4, popularity: 8500, desc: "Classic slim fit with stretch." },

  # Clothing > Women's
  { name: "Align Leggings", category: "Clothing > Women's Clothing", brand: "Lululemon", price: 9800, stock: 180, rating: 4.8, popularity: 9500, desc: "Buttery soft Nulu fabric, high-rise." },
  { name: "Cloud 5 Sneakers", category: "Clothing > Shoes", brand: "On Running", price: 15000, stock: 120, rating: 4.6, popularity: 8800, desc: "Lightweight daily trainer with CloudTec." },
  { name: "Better Sweater Jacket", category: "Clothing > Women's Clothing", brand: "Patagonia", price: 15900, stock: 90, rating: 4.7, popularity: 7800, desc: "Recycled polyester fleece, fair trade." },

  # Home & Garden > Furniture
  { name: "Aeron Chair", category: "Home & Garden > Furniture", brand: "Herman Miller", price: 159500, stock: 10, rating: 4.9, popularity: 7000, desc: "Ergonomic masterpiece with 12-year warranty." },
  { name: "KALLAX Shelf Unit", category: "Home & Garden > Furniture", brand: "IKEA", price: 7999, stock: 200, rating: 4.6, popularity: 9000, desc: "Versatile storage, multiple configurations." },
  { name: "Mid-Century Sofa", category: "Home & Garden > Furniture", brand: "West Elm", price: 129900, stock: 15, rating: 4.5, popularity: 6800, desc: "FSC-certified frame, performance fabric." },

  # Home & Garden > Kitchen
  { name: "Stand Mixer Artisan", category: "Home & Garden > Kitchen", brand: "KitchenAid", price: 44999, stock: 50, rating: 4.8, popularity: 8200, desc: "Iconic 5-quart tilt-head, 10 speeds." },
  { name: "Barista Pro Espresso", category: "Home & Garden > Kitchen", brand: "Breville", price: 84999, stock: 30, rating: 4.7, popularity: 7500, desc: "ThermoJet heating, integrated grinder." },

  # Sports & Outdoors > Fitness
  { name: "Bike+", category: "Sports & Outdoors > Fitness", brand: "Peloton", price: 249500, stock: 10, rating: 4.6, popularity: 7000, desc: "Rotating HD touchscreen, auto-follow." },
  { name: "Adjustable Dumbbells 5-52.5lb", category: "Sports & Outdoors > Fitness", brand: "Bowflex", price: 42900, stock: 60, rating: 4.7, popularity: 8000, desc: "Space-saving, replaces 15 sets." },

  # Sports & Outdoors > Camping
  { name: "Base Camp 6 Tent", category: "Sports & Outdoors > Camping", brand: "The North Face", price: 79999, stock: 25, rating: 4.7, popularity: 6800, desc: "Spacious 6-person, weather-resistant." },
  { name: "Rambler 20oz Tumbler", category: "Sports & Outdoors > Camping", brand: "YETI", price: 3500, stock: 300, rating: 4.8, popularity: 9200, desc: "Double-wall vacuum insulation." },

  # Books > Fiction
  { name: "Fourth Wing", category: "Books > Fiction", brand: "Penguin Random House", price: 1899, stock: 500, rating: 4.6, popularity: 9800, desc: "Dragon riders, romance, and war." },
  { name: "Iron Flame", category: "Books > Fiction", brand: "Penguin Random House", price: 1999, stock: 400, rating: 4.7, popularity: 9500, desc: "Sequel to Fourth Wing." },
  { name: "The Women", category: "Books > Fiction", brand: "Macmillan", price: 1799, stock: 300, rating: 4.8, popularity: 9000, desc: "Vietnam War nurse's story by Kristin Hannah." },

  # Books > Non-Fiction
  { name: "Atomic Habits", category: "Books > Non-Fiction", brand: "Penguin Random House", price: 1699, stock: 600, rating: 4.8, popularity: 9900, desc: "Tiny changes, remarkable results." },
  { name: "Outlive", category: "Books > Non-Fiction", brand: "Harmony", price: 1999, stock: 350, rating: 4.7, popularity: 8800, desc: "Science of longevity by Peter Attia." }
]

product_data.each_with_index do |data, index|
  category = category_records[data[:category]]
  brand = brand_records[data[:brand]]
  next unless category && brand

  product = Product.find_or_create_by!(slug: data[:name].parameterize) do |p|
    p.name = data[:name]
    p.sku = random_sku(category.slug[0..2].upcase)
    p.description = data[:desc]
    p.price_cents = data[:price]
    p.stock_count = data[:stock]
    p.rating_avg = data[:rating]
    p.popularity_score = data[:popularity]
    p.category = category
    p.brand = brand
    p.active = true
  end

  # Add random labels
  label_samples = label_records.values.sample(rand(1..3))
  label_samples.each do |label|
    ProductLabel.find_or_create_by!(product: product, label: label)
  end

  print "." if index % 10 == 0
end

# Create a cart for testing
Cart.find_or_create_by!(id: 1)

puts "\nSeeding complete!"
puts "Categories: #{Category.count}"
puts "Brands: #{Brand.count}"
puts "Labels: #{Label.count}"
puts "Products: #{Product.count}"
puts "Product Labels: #{ProductLabel.count}"

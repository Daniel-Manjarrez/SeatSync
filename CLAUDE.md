# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SeatSync is a Rails 8.0 restaurant analytics application that tracks receipts, menu items, and ingredient usage. It uses OCR (Tesseract) to extract data from receipt images and provides a comprehensive analytics dashboard.

## Development Commands

### Database Setup
```bash
# Create database
rails db:create

# Run migrations
rails db:migrate

# Seed with 10 menu items, 24 ingredients, and 3 sample receipts
rails db:seed

# Reset everything (drop, create, migrate, seed)
rails db:reset

# Clear receipts only (keep menu items and ingredients)
rails runner "ReceiptItem.destroy_all; Receipt.destroy_all"
```

### Server
```bash
# Start development server
rails server

# Access at http://localhost:3000 (redirects to /dashboard)
```

### Testing
```bash
# RSpec unit tests (18 examples expected)
bundle exec rspec

# Run specific test file
bundle exec rspec spec/services/receipt_parser_spec.rb

# Run specific test by line number
bundle exec rspec spec/services/receipt_parser_spec.rb:11

# Cucumber integration tests (10 scenarios, 75 steps expected)
bundle exec cucumber

# Run specific feature
bundle exec cucumber features/upload_receipt.feature

# Run all tests
bundle exec rspec && bundle exec cucumber
```

### Test Database Setup (one-time)
```bash
RAILS_ENV=test rails db:create
RAILS_ENV=test rails db:migrate
```

## Architecture Overview

### Data Flow
1. **Receipt Upload** → OCR extraction (ReceiptParser) → Fuzzy matching (ItemMatcher) → Database storage
2. **Dashboard** → Receipt queries → Analytics calculations (AnalyticsCalculator) → Chart.js visualization

### Database Schema
```
Receipt
├── has_one_attached :image (Active Storage)
├── has_many :receipt_items
└── has_many :items (through: :receipt_items)

ReceiptItem (join table)
├── belongs_to :receipt
├── belongs_to :item
└── quantity: integer

Item (menu items)
├── has_many :receipt_items
├── has_many :receipts (through: :receipt_items)
├── price: decimal
├── category: string (Appetizers, Entrees, Sides, Desserts, Beverages)
└── recipes: JSON {ingredient_name => amount_per_serving}

Ingredient
├── name: string (unique)
└── unit: string (default: 'lbs')
```

### Service Architecture

**ReceiptParser** (`app/services/receipt_parser.rb`)
- Uses RTesseract gem to perform OCR on receipt images
- Extracts: date, time, items with quantities, subtotal, total, tip, tax
- Smart fallback: calculates total from subtotal + tax if OCR misreads
- Returns structured data: `{date:, time:, items: [{text:, quantity:}], subtotal:, total:, tip:}`

**ItemMatcher** (`app/services/item_matcher.rb`)
- Fuzzy matching using Levenshtein distance algorithm
- Three-tier strategy: exact match → substring match → fuzzy match
- Configurable threshold: `SIMILARITY_THRESHOLD = 0.6`
- Returns: `{item: Item, confidence: 0.85, quantity: 1}`
- Adjust threshold in `item_matcher.rb:6` if OCR matching is too strict/loose

**AnalyticsCalculator** (`app/services/analytics_calculator.rb`)
- Comprehensive restaurant metrics calculator
- Initialized with receipts collection: `AnalyticsCalculator.new(receipts)`
- Provides 30+ metric methods organized by category:
  - Revenue: `daily_revenue`, `weekly_revenue`, `monthly_revenue`, `revenue_by_category`
  - Growth: `week_over_week_growth`, `month_over_month_growth`
  - Menu: `most_popular_items`, `product_performance`, `item_attachment_rate`
  - Timing: `orders_by_hour`, `revenue_by_meal_period`, `time_between_orders`
  - Other: `average_spend`, `occupancy_rate`, `price_point_distribution`

### Controllers

**ReceiptsController** (`app/controllers/receipts_controller.rb:10-62`)
- `create` action workflow:
  1. Create receipt with temporary data
  2. Save to persist Active Storage image
  3. Parse image with ReceiptParser
  4. Match OCR items to menu items with ItemMatcher
  5. Update receipt + create ReceiptItems in transaction
- Always includes `receipt_items: :item` for N+1 prevention

**DashboardController** (`app/controllers/dashboard_controller.rb`)
- Single `index` action computes all metrics
- Loads receipts with `includes(receipt_items: :item)` for performance
- Initializes AnalyticsCalculator and calls ~20 metric methods
- Passes all data to view via instance variables

### Receipt Parsing Logic

The OCR pipeline handles common parsing challenges:
- **Date extraction**: Matches MM/DD/YYYY patterns, defaults to `Date.today`
- **Time extraction**: Matches HH:MM or HH:MM AM/PM, defaults to current time
- **Item extraction**: Matches `"quantity item_name"` patterns (e.g., "2 Chicken Parmesan")
- **Financial parsing**: Regex for subtotal, total, tip, tax with OCR error tolerance (e.g., "suptotal")
- **Smart total calculation**: If OCR total ≠ subtotal + tax (within $1), recalculates

### Ingredient Tracking

Receipts can calculate ingredient usage via `Receipt#calculate_ingredient_usage`:
- Iterates through `receipt_items`
- Looks up `item.recipes` (JSON hash: `{ingredient => amount_per_serving}`)
- Multiplies by quantity ordered
- Returns hash of total ingredient usage

Class method `Receipt.ingredient_usage_report(start_date, end_date)` aggregates across date ranges.

## Key Files

- **Routes**: `config/routes.rb` - RESTful receipts, dashboard at `/dashboard`, root redirects to dashboard
- **Models**: `app/models/` - Receipt, Item, ReceiptItem, Ingredient
- **Services**: `app/services/` - ReceiptParser, ItemMatcher, AnalyticsCalculator
- **Migrations**: `db/migrate/` - 7 migrations (receipts, active_storage, items, receipt_items, ingredients, table_size, financial_fields)
- **Seed Data**: `db/seeds.rb` - 10 Italian menu items, 24 ingredients, 3 sample receipts
- **Menu Reference**: `MENU.md` - Ingredient recipes for all 10 menu items

## Deployment

- **Production**: Heroku (https://fierce-scrubland-45377-5e74d2d7f81b.herokuapp.com/dashboard)
- **Database**: PostgreSQL in production (`pg` gem), SQLite3 in dev/test
- **Dependencies**: Tesseract OCR must be installed on deployment environment

## Common Patterns

### Adding New Menu Items
```ruby
Item.create!(
  name: 'Item Name',
  price: 12.99,
  category: 'Entrees', # or Appetizers, Sides, Desserts, Beverages
  recipes: {
    'Ingredient 1' => 0.5,  # 0.5 lbs per serving
    'Ingredient 2' => 0.3
  }
)
```

### Querying with Performance
Always use `includes` to avoid N+1 queries:
```ruby
Receipt.includes(receipt_items: :item).all
Receipt.includes(receipt_items: :item).order(created_at: :desc)
```

### Debugging OCR
View Rails logs to see extracted text and matching results:
- OCR output appears in `ReceiptParser`
- Matching results logged with ✅/❌ emojis in `ItemMatcher`

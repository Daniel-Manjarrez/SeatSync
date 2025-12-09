# SeatSync Setup Guide

Quick setup guide to get the project running.

## Prerequisites

- Ruby 3.3.0
- Azure OpenAI credentials (endpoint, API key, deployment name, API version)

## Setup

### 1. Install Ruby 3.3.0

```bash
rbenv install 3.3.0
rbenv local 3.3.0
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Configure Environment

Create a `.env` file (or export variables) with your Azure OpenAI settings:
```
AZURE_OPENAI_ENDPOINT="https://<your-resource>.openai.azure.com"
AZURE_OPENAI_API_KEY="..."
AZURE_OPENAI_API_VERSION="2024-02-15-preview"
AZURE_OPENAI_CHAT_DEPLOYMENT="gpt-4o"
```

### 4. Setup Database

```bash
rails db:create
rails db:migrate
rails db:seed
```

This creates:
- Receipts, Items, Ingredients, and ReceiptItems tables
- 10 menu items with recipes
- 24 ingredients
- 3 sample receipts

### 5. Start Server

```bash
rails server
```

Visit: http://localhost:3000/dashboard

## Usage

- **Dashboard**: http://localhost:3000/dashboard
- **Upload Receipt**: http://localhost:3000/receipts/new
- **Ingredients**: http://localhost:3000/ingredients

## Key Migrations

The database has 7 migrations that create:

1. `receipts` - Stores receipt metadata (date, time, order_items)
2. `active_storage` - Handles receipt image attachments
3. `items` - Menu items with prices and recipes (JSON)
4. `receipt_items` - Links receipts to items with quantities
5. `ingredients` - Available ingredients for tracking
6. `table_size` - Added to receipts table
7. `financial_fields` - Added subtotal, total, tip to receipts

## Database Schema

```
Receipt (has_one :image, has_many :receipt_items)
  ├── ReceiptItem (belongs_to :receipt, belongs_to :item)
  │     └── Item (menu items with recipes)
  └── Ingredient (referenced in Item.recipes JSON)
```

## How It Works

1. Upload receipt image → OCR extracts text
2. Parser identifies items and quantities
3. Fuzzy matching links OCR text to menu items
4. Creates receipt_items and updates dashboard

## Useful Commands

```bash
# Clear all receipts (keep menu items)
rails runner "ReceiptItem.destroy_all; Receipt.destroy_all"

# Reset everything
rails db:reset

# Run tests
bundle exec rspec
bundle exec cucumber
```

## Troubleshooting

**OCR not matching items**
- Check image quality
- View Rails logs for OCR output
- Adjust confidence threshold in `app/services/item_matcher.rb`

## Project Structure

- **Services**: `app/services/` (ReceiptParser, ItemMatcher, AnalyticsCalculator)
- **Models**: `app/models/` (Receipt, Item, ReceiptItem, Ingredient)
- **Controllers**: `app/controllers/` (ReceiptsController, DashboardController)
- **Migrations**: `db/migrate/`
- **Seed Data**: `db/seeds.rb`

---

**You're ready to go!** 🚀

# SeatSync — Engineering Software-as-a-Service Project

SeatSync is a receipt tracking application that allows users to upload receipt images, automatically extract meal information (date, time, and food items), and view their expense history on a dashboard.

### Team Members

| Name   | UNI  |
|--------|-----|
| Daniel Manjarrez    | dam2274 |
| Brandon Pae  | btp2109 |
| Kevin Gutierrez   | kmg2226 |
| Jivin Yalamanchili | jy3375 |

---

## 🚀 Live Deployment

The application is deployed on Heroku and can be accessed at:

**[https://fierce-scrubland-45377-5e74d2d7f81b.herokuapp.com/dashboard](https://fierce-scrubland-45377-5e74d2d7f81b.herokuapp.com/dashboard)**

---

## Table of Contents
- [Running the Application Locally](#running-the-application-locally)
- [Running Tests](#running-tests)
  - [RSpec Unit Tests](#running-rspec-tests)
  - [Cucumber Integration Tests](#running-cucumber-tests)

---

## Features

### 🎯 Restaurant Analytics Dashboard
- **Modern Dark Theme UI** - Sleek, professional dashboard with gradient backgrounds
- **Real-time Metrics Display** - Key performance indicators at a glance
- **Interactive Charts** - Powered by Chart.js for data visualization
- **Responsive Design** - Works on desktop, tablet, and mobile devices
- **Sidebar Navigation** - Easy access to all sections

### 📊 Dashboard Metrics
- Total Amount
- Order Count
- Average Costs
- Profit Margin
- Customer Engagement Score
- Category Breakdown (Food, Dessert, Drink)
- Product Sales Analysis

### 📸 Receipt Tracking
- Upload receipt images
- OCR-powered data extraction
- View receipt history

## Running the Application Locally

### Prerequisites
- Ruby 3.3
- Rails 8.0
- SQLite3 (for development/test)
- Bundler

### Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-username/SeatSync.git
   cd SeatSync
   ```

2. **Install Dependencies**
   ```bash
   bundle install
   ```

3. **Install Tesseract OCR**
   ```bash
   sudo apt-get update
   sudo apt-get install -y tesseract-ocr
   ```

4. **Setup Database**
   ```bash
   # Create the database
   rails db:create

   # Run migrations
   rails db:migrate

   # (Optional) Seed with sample data
   rails db:seed
   ```

5. **Start the Rails Server**
   ```bash
   rails server
   ```

6. **Access the Application**

   Open your web browser and navigate to:
   ```
   http://localhost:3000
   ```

   You should be automatically redirected to the restaurant dashboard at:
   ```
   http://localhost:3000/dashboard
   ```
   
   **Main Features:**
   - 📊 **Dashboard** - Modern analytics dashboard with charts and metrics
   - 🧾 **Receipts** - Access via sidebar "Sales" or `/receipts`

### Using the Application

#### Upload a Receipt
1. Click "Upload New Receipt" on the dashboard
2. Select a receipt image (JPG, PNG, or HEIC format)
3. Click "Upload Photo"
4. View the extracted information on the dashboard

#### View Receipt History
- The dashboard displays all uploaded receipts with:
  - Date
  - Time
  - List of food items
- Click "View" to see individual receipt details and the original image

#### Sample Data
If you ran `rails db:seed`, you'll see 5 sample receipts with various meal data for testing.

---

## Running Tests

### Test File Locations

**RSpec Unit Tests** are located in:
- `spec/controllers/` - Controller tests
- `spec/models/` - Model tests
- `spec/services/` - Service tests

**Cucumber Integration Tests** are located in:
- `features/*.feature` - Feature files with test scenarios
  - `features/analytics.feature` - Analytics calculation tests
  - `features/dashboard.feature` - Dashboard display tests
  - `features/dashboard_navigation.feature` - Navigation tests
  - `features/upload_receipt.feature` - Receipt upload tests
- `features/step_definitions/` - Step definition implementations

---

## Running RSpec Tests

### One-Time Setup

1. Install dependencies:
```bash
bundle install
```

2. Setup test database:
```bash
RAILS_ENV=test rails db:create
RAILS_ENV=test rails db:migrate
```

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/services/receipt_parser_spec.rb
bundle exec rspec spec/controllers/receipts_controller_spec.rb

# Run specific test by line number
bundle exec rspec spec/services/receipt_parser_spec.rb:11
```

### Expected Output for Running All RSpec Tests
```
242 examples, 0 failures
```

## Running Cucumber Tests

### One-Time Setup
Already complete if you ran RSpec setup above.

### Running Tests

```bash
# Run all Cucumber features
bundle exec cucumber

# Run specific feature
bundle exec cucumber features/upload_receipt.feature

# Run specific scenario by line number
bundle exec cucumber features/upload_receipt.feature:6
```

### Expected Output for Running All Cucumber Tests
```
29 scenarios (29 passed)
164 steps (164 passed)
```

### Run All Tests (RSpec + Cucumber)
```bash
bundle exec rspec && bundle exec cucumber
```

### Erase Database + Cached Data, Then Repopulate Seed
```bash
rails console

ReceiptItem.delete_all
Receipt.delete_all
ActiveStorage::Attachment.where(record_type: "Receipt").find_each(&:purge)
ActiveStorage::Blob.joins(:attachments).where(active_storage_attachments: { record_type: "Receipt" }).find_each(&:purge)
Rails.cache.clear

exit

rails db:seed
```
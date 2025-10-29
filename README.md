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

3. **Setup Database**
   ```bash
   # Create the database
   rails db:create

   # Run migrations
   rails db:migrate

   # (Optional) Seed with sample data
   rails db:seed
   ```

4. **Start the Rails Server**
   ```bash
   rails server
   ```

5. **Access the Application**

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

### Expected Output
```
1 examples, 0 failures
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

### Expected Output
```
2 scenarios (2 passed)
14 steps (14 passed)
```

### Run All Tests (RSpec + Cucumber)
```bash
bundle exec rspec && bundle exec cucumber
```

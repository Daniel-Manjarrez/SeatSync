# SeatSync — Engineering Software-as-a-Service Project

### Team Members

| Name   | UNI  |
|--------|-----|
| Daniel Manjarrez    | dam2274 |
| Brandon Pae  | btp2109 |
| Kevin Gutierrez   | kmg2226 |
| Jivin Yalamanchili | jy3375 |

---

## How to Run and Test the Project

Follow the steps below to set up and run the project on your local machine:

1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-username/your-repo.git

Follow the steps below to set up and test the project on your local machine:

1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-username/your-repo.git

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
bundle exec rspec spec/models/receipt_spec.rb
bundle exec rspec spec/controllers/receipts_controller_spec.rb

# Run specific test by line number
bundle exec rspec spec/models/receipt_spec.rb:10
```

### Expected Output
```
18 examples, 0 failures
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

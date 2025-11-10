Feature: Dashboard Navigation and Controllers
  As a user
  So that I can navigate the application
  I want all pages to work correctly

Scenario: Access dashboard from home
  When I go to the home page
  Then I should be on the dashboard page

Scenario: View dashboard with all tabs
  Given the following test receipts exist:
    | date       | time  | items                   |
    | 2024-12-01 | 08:00 | Coffee,Croissant       |
    | 2024-12-15 | 12:00 | Burger,Fries,Soda      |
  Given I am on the dashboard page
  Then I should see "Overview"
  When I follow "Revenue Analysis"
  Then I should see "Weekday Performance"
  When I follow "Menu Performance"
  Then I should see "Top 10 Most Popular Items"
  When I follow "Timing & Operations"
  Then I should see "15-Minute Intervals"

Scenario: Navigate between all pages
  Given I am on the dashboard page
  When I follow "Upload Images"
  Then I should see "Upload Receipt"
  When I go to the dashboard page
  Then I should see "Restaurant Analytics"
  When I follow "Ingredients Dashboard"
  Then I should see "Ingredients Dashboard"

Scenario: View receipts with and without data
  Given I am on the receipts page
  When there are no existing receipts
  Then I should see "No receipts uploaded yet"
  Given a receipt exists with date "2025-01-20" and time "12:00"
  When I go to the receipts page
  Then I should see "2025-01-20"

Feature: Restaurant Analytics Dashboard
  As a restaurant manager
  So that I can track business performance
  I want to view comprehensive analytics

Background:
  Given the following test receipts exist:
    | date       | time  | items                   |
    | 2024-12-01 | 08:00 | Coffee,Croissant       |
    | 2024-12-15 | 12:00 | Burger,Fries,Soda      |
    | 2025-01-15 | 12:30 | Pizza,Soda             |
    | 2025-01-16 | 19:00 | Steak,Salad            |
    | 2025-01-22 | 12:15 | Burger,Fries           |

Scenario: View complete dashboard with all metrics
  Given I am on the dashboard page
  Then I should see "Restaurant Analytics"
  And I should see "Total Orders"
  And I should see "Occupancy Rate"
  And I should see "WoW"
  And I should see "MoM"

Scenario: Navigate all dashboard tabs
  Given I am on the dashboard page
  When I follow "Overview"
  Then I should see "Daily Revenue Trend"
  When I follow "Revenue Analysis"
  Then I should see "Monthly Revenue Trend"
  When I follow "Menu Performance"
  Then I should see "Burger"
  When I follow "Timing & Operations"
  Then I should see "Avg Orders/Hour"

Scenario: Access all pages from sidebar
  Given I am on the dashboard page
  When I follow "Upload Images"
  Then I should be on the upload receipt page
  When I go to the dashboard page
  Then I should see "Restaurant Analytics"
  When I follow "Ingredients Dashboard"
  Then I should see "Ingredients Dashboard"


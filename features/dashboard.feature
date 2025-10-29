Feature: Restaurant Analytics Dashboard
  As a restaurant manager
  So that I can track business performance
  I want to view comprehensive analytics

Scenario: View complete dashboard with all metrics
  Given I am on the dashboard page
  Then I should see "Restaurant Analytics"
  And I should see "Total Orders"
  And I should see "Occupancy Rate"
  And I should see "50"
  And I should see "78.5"
  And I should see "WoW"
  And I should see "MoM"

Scenario: Navigate all dashboard tabs
  Given I am on the dashboard page
  When I follow "Revenue Analysis"
  Then I should see "Monthly Revenue Trend"
  When I follow "Menu Performance"
  Then I should see "Burger"
  When I follow "Timing & Operations"
  Then I should see "Avg Orders/Hour"
  When I follow "Overview"
  Then I should see "Daily Revenue Trend"

Scenario: Access all pages from sidebar
  Given I am on the dashboard page
  When I follow "Upload Images"
  Then I should be on the upload receipt page
  When I go to the dashboard page
  Then I should see "Restaurant Analytics"
  When I follow "Ingredients Dashboard"
  Then I should see "Margherita Pizza"


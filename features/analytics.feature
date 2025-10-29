Feature: Analytics Calculations
  As a system
  So that metrics are calculated correctly
  I want to test all analytics calculator methods

Background:
  Given the following test receipts exist:
    | date       | time  | items                   |
    | 2024-12-01 | 08:00 | Coffee,Croissant       |
    | 2024-12-15 | 12:00 | Burger,Fries,Soda      |
    | 2025-01-15 | 12:30 | Pizza,Soda             |
    | 2025-01-16 | 19:00 | Steak,Salad            |
    | 2025-01-22 | 12:15 | Burger,Fries           |

Scenario: Calculate all core metrics
  When I run all analytics calculations
  Then total orders should equal 5
  And average order size should be calculated
  And average spend should be calculated
  And most popular item should be "Burger"
  And revenue by day of week should have all days
  And revenue by meal period should have all periods
  And orders by hour should be grouped
  And weekday vs weekend should be compared
  And growth metrics should be calculated
  And price distribution should be categorized
  And product performance should be ranked
  And item pairing should be analyzed


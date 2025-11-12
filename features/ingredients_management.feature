Feature: Manage menu items and ingredients
  As a kitchen manager
  So that ingredient analytics stay accurate
  I want to manage menu item recipes with proper error handling

  Background:
    Given I am on the ingredients page

  Scenario: Create a menu item with aggregated ingredients
    When I create an item "Garden Salad" with price "8.50" and category "Appetizers" and ingredients:
      | name     | amount |
      | lettuce  | 1.0    |
      | Lettuce  | 0.5    |
      | tomatoes | 0.25   |
      |          | 2.0    |
    Then the flash "notice" should include "Item created: Garden Salad"
    And the item "Garden Salad" should have recipes:
      | ingredient | amount |
      | Lettuce    | 1.5    |
      | Tomatoes   | 0.25   |

  Scenario: Show validation errors when required fields are missing
    When I create an item "" with price "" and category "Appetizers" and ingredients:
      | name | amount |
      | Kale | 0.5    |
    Then the flash "alert" should include "can't be blank"
    And the item "Kale" should not exist

  Scenario: Prevent deleting items that appear on receipts
    Given an item "Receipt Special" exists with price 12.00 category "Entrees" and recipes:
      | ingredient | amount |
      | Beef       | 1.0    |
    And the item "Receipt Special" appears on a receipt
    When I delete the item "Receipt Special"
    Then the flash "alert" should include "Cannot delete item that appears on receipts"
    And the item "Receipt Special" should exist

  Scenario: Show error when deleting a missing item
    When I delete the item with id 999999
    Then the flash "alert" should include "Item not found"

  Scenario: Show error when updating a missing item
    When I update the item with id 888888 with recipes:
      | name  | amount |
      | Basil | 0.1    |
    Then the flash "alert" should include "Item not found"

  Scenario: Update a menu item and add new ingredients
    Given an item "Roasted Chicken" exists with price 18.00 category "Entrees" and recipes:
      | ingredient | amount |
      | Chicken    | 1.0    |
      | Garlic     | 0.1    |
    When I update the item "Roasted Chicken" with recipes:
      | name     | amount |
      | Chicken  | 1.5    |
      | Rosemary | 0.05   |
      | Garlic   | 0.0    |
    Then the flash "notice" should include "Updated recipe: Roasted Chicken"
    And the item "Roasted Chicken" should have recipes:
      | ingredient | amount |
      | Chicken    | 1.5    |
      | Rosemary   | 0.05   |

  Scenario: Surface failures when updating a menu item
    Given an item "Faulty Soup" exists with price 9.00 category "Entrees" and recipes:
      | ingredient | amount |
      | Broth      | 1.0    |
    And future item saves will fail with "Database unavailable"
    When I update the item "Faulty Soup" with recipes:
      | name  | amount |
      | Broth | 1.2    |
    Then the flash "alert" should include "Database unavailable"


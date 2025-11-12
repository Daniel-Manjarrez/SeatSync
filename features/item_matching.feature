Feature: Item matching from OCR
  As a reconciliation specialist
  So that OCR output maps to real menu items
  I want the item matcher to resolve names and quantities reliably

  Background:
    Given the menu database is cleared
    And the following menu items exist:
      | name              | price | category  |
      | Burger            | 10.00 | Entrees   |
      | Fries             | 3.00  | Sides     |
      | Chicken Parmesan  | 18.00 | Entrees   |
      | Caesar Salad      | 9.50  | Appetizers |
      | Tacos             | 2.50  | Entrees   |
      | Nachos            | 3.00  | Appetizers |
      | Lemonade          | 2.00  | Beverages |
      | Bread Pudding     | 6.00  | Desserts  |

  Scenario: Exact matches keep OCR quantities when subtotal aligns
    When I match OCR items with subtotal 19.20:
      | text   | quantity | line_price |
      | Burger | 1        | 10.00      |
      | Fries  | 3        | 3.00       |
    Then the matched results should be:
      | text   | item   | quantity | confidence |
      | Burger | Burger | 1        | 1.0        |
      | Fries  | Fries  | 3        | 1.0        |

  Scenario: Single item subtotal correction finds new quantity
    When I match OCR items with subtotal 54.00:
      | text             | quantity | line_price |
      | Chicken Parmesan | 1        | 18.00      |
    Then the matched results should be:
      | text             | item              | quantity |
      | Chicken Parmesan | Chicken Parmesan  | 3        |

  Scenario: Combination search adjusts quantities for small orders
    When I match OCR items with subtotal 8.00:
      | text   | quantity | line_price |
      | Tacos  | 1        | 2.50       |
      | Nachos | 1        | 3.00       |
    Then the matched results should be:
      | text   | item   | quantity |
      | Tacos  | Tacos  | 2        |
      | Nachos | Nachos | 1        |

  Scenario: Greedy adjustment falls back when no exact subtotal fits
    When I match OCR items with subtotal 36.00:
      | text            | quantity | line_price |
      | Burger          | 1        | 10.00      |
      | Fries           | 1        | 3.00       |
      | Lemonade        | 1        | 2.00       |
      | Bread Pudding   | 1        | 6.00       |
    Then the matched results should be:
      | text            | item            | quantity |
      | Burger          | Burger          | 1        |
      | Fries           | Fries           | 1        |
      | Lemonade        | Lemonade        | 1        |
      | Bread Pudding   | Bread Pudding   | 1        |

  Scenario: Substring matching resolves embedded names
    When I match the OCR text "Large Burger Combo"
    Then the single match should be "Burger" with confidence 0.9

  Scenario: Fuzzy matching resolves misspelled names
    When I match the OCR text "Chikn Parmsn"
    Then the single match should be "Chicken Parmesan" with confidence above 0.6

  Scenario: Blank OCR input returns no match
    When I match the OCR text ""
    Then there should be no match


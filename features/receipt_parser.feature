Feature: Receipt parsing heuristics
  As a developer
  So that OCR output is interpreted correctly
  I want to verify the receipt parser handles common patterns and failures

  Scenario: Parse receipt text and fix incorrect totals
    Given the OCR text is:
      """
      01/31/2025
      12:45 PM
      2 Burger 14.99
      Subtotal: 29.98
      Tax 2.40
      Total 10.00
      Tip: 5.00
      """
    And a fake receipt image is available
    And the OCR engine will return that text
    When I parse the receipt image
    Then the parsed date should be "2025-01-31"
    And the parsed time should be "12:45 PM"
    And the parsed subtotal should be 29.98
    And the parsed total should equal the subtotal plus tax
    And the parsed tip should be 5.0
    And the parsed items should include:
      | text   | quantity | line_price |
      | Burger | 2        | 14.99      |
    And parsing should succeed

  Scenario: Handle OCR errors gracefully
    Given a fake receipt image is available
    And the OCR engine will raise "OCR timeout"
    When I parse the receipt image
    Then parsing should fail with defaults


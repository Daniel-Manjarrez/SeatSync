Feature: Upload and view receipt
  As a user tracking my expenses
  So that I can automatically extract receipt information
  I want to upload receipt photos and view them on my dashboard

Scenario: Successfully upload a receipt and view it on dashboard
  Given I am on the upload receipt page
  And the receipt parser will return test data
  When I attach a receipt image
  And I press "Upload Photo"
  Then I should see "Receipt uploaded successfully"
  And I should be on the receipts page
  And I should see "2025-01-15"
  And I should see "14:30"
  And I should see "Burger"
  And I should see "Fries"
  And I should see "Soda"

Scenario: Dashboard displays existing receipts
  Given a receipt exists with date "2025-01-20" and time "12:00"
  When I go to the receipts page
  Then I should see "2025-01-20"
  And I should see "12:00"

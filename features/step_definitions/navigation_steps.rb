# Navigation Steps

When('there are no existing receipts') do
  Receipt.destroy_all
  visit '/receipts'
end


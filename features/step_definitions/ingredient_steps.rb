module IngredientStepHelpers
  def routes
    Rails.application.routes.url_helpers
  end

  def submit_request(method, path, params = {})
    page.driver.submit(method, path, params)
    flash_hash = page.driver.request.session['flash']
    raw =
      if flash_hash.respond_to?(:[]) && flash_hash['flashes']
        flash_hash['flashes']
      elsif flash_hash.respond_to?(:to_hash)
        flash_hash.to_hash
      elsif flash_hash.respond_to?(:instance_variable_get)
        flash_hash.instance_variable_get(:@flashes) || {}
      else
        {}
      end
    if raw.present?
      @last_flash = raw.each_with_object({}) { |(k, v), memo| memo[k.to_s] = v }
    else
      @last_flash = {}
    end
    if page.driver.respond_to?(:follow_redirect!)
      page.driver.follow_redirect!
    end
  end
end

World(IngredientStepHelpers)

When('I create an item {string} with price {string} and category {string} and ingredients:') do |name, price, category, table|
  params = {
    name: name,
    price: price,
    category: category,
    ingredients: table.hashes
  }
  submit_request(:post, routes.items_path, params)
end

Given('an item {string} exists with price {float} category {string} and recipes:') do |name, price, category, table|
  recipes = {}
  table.hashes.each do |row|
    ingredient_name = row['ingredient']
    amount = row['amount'].to_f
    recipes[ingredient_name] = amount
    Ingredient.find_or_create_by!(name: ingredient_name) do |ing|
      ing.unit = 'lbs'
    end
  end

  Item.create!(
    name: name,
    price: price,
    category: category,
    recipes: recipes
  )
end

Given('the item {string} appears on a receipt') do |name|
  item = Item.find_by!(name: name)
  receipt = Receipt.create!(
    receipt_date: Date.today,
    receipt_time: '12:00',
    order_items: [name]
  )
  receipt.receipt_items.create!(item: item, quantity: 1)
end

When('I delete the item {string}') do |name|
  item = Item.find_by!(name: name)
  submit_request(:delete, routes.item_path(item))
end

When('I delete the item with id {int}') do |id|
  submit_request(:delete, routes.item_path(id))
end

When('I update the item {string} with recipes:') do |name, table|
  item = Item.find_by!(name: name)
  params = { recipes: table.hashes }
  submit_request(:patch, routes.item_path(item), params)
end

When('I update the item with id {int} with recipes:') do |id, table|
  params = { recipes: table.hashes }
  submit_request(:patch, routes.item_path(id), params)
end

Then('the item {string} should have recipes:') do |name, table|
  item = Item.find_by!(name: name)
  actual_recipes = item.reload.recipes || {}

  expected = table.hashes.each_with_object({}) do |row, memo|
    memo[row['ingredient']] = row['amount'].to_f
  end

  expect(actual_recipes.keys).to match_array(expected.keys)
  expected.each do |ingredient, amount|
    expect(actual_recipes[ingredient].to_f).to be_within(0.001).of(amount)
  end
end

Then('the item {string} should not exist') do |name|
  expect(Item.exists?(name: name)).to be false
end

Then('the item {string} should exist') do |name|
  expect(Item.exists?(name: name)).to be true
end

Given('future item saves will fail with {string}') do |message|
  allow_any_instance_of(Item).to receive(:save) do |instance|
    instance.errors.add(:base, message) unless instance.errors[:base].include?(message)
    false
  end
end

Then('the flash {string} should include {string}') do |type, text|
  expect(@last_flash).to be_a(Hash), 'Expected a flash hash but none was captured'
  message = @last_flash[type]
  expect(message).to be_present, "Expected flash #{type} to be present"
  expect(message).to include(text)
end


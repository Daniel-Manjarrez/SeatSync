class IngredientsController < ApplicationController
  layout 'dashboard'
  
  def index
    @ingredients = Ingredient.all.order(:name)
    @items = Item.all.order(:name)
    
    # Calculate ingredient usage for current month
    start_date = Date.today.beginning_of_month
    end_date = Date.today.end_of_month
    @ingredient_usage = Receipt.ingredient_usage_report(start_date, end_date)
    
    # Calculate usage for last month for comparison
    last_month_start = 1.month.ago.beginning_of_month
    last_month_end = 1.month.ago.end_of_month
    @last_month_usage = Receipt.ingredient_usage_report(last_month_start, last_month_end)
    # Ensure all ingredients exist in the usage hash (show zero for new ingredients)
    @ingredients.each do |ing|
      @ingredient_usage[ing.name] ||= 0
      @last_month_usage[ing.name] ||= 0
    end
  end
end


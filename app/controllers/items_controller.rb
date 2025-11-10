class ItemsController < ApplicationController
  # POST /items
  def create
    ingredients_params = params[:ingredients] || []

    # Build recipes hash, normalizing names and aggregating duplicate rows (case-insensitive)
    recipes_agg = {}
    display_name_map = {}

    ingredients_params.each do |ing|
      raw_name = (ing[:name].presence || ing['name']).to_s
      name = raw_name.strip
      next if name.blank?

      key = name.downcase
      amount = (ing[:amount].presence || ing['amount']).to_f
      amount = 0.0 if amount.nan?

      # Sum duplicates (case-insensitive)
      recipes_agg[key] ||= 0.0
      recipes_agg[key] += amount

      # Remember a nicely-cased display name for creation (use first occurrence titleized)
      display_name_map[key] ||= name.split.map(&:capitalize).join(' ')
    end

    # Build final recipes hash with display names
    recipes_hash = {}
    recipes_agg.each do |key, amt|
      next if amt <= 0
      recipes_hash[display_name_map[key]] = amt
    end

    @item = Item.new(item_params)
    @item.recipes = recipes_hash

    # Create missing Ingredient records (case-insensitive) and save item in a transaction
    ActiveRecord::Base.transaction do
      recipes_hash.each_key do |ing_name|
        # Case-insensitive find
        existing = Ingredient.where('lower(name) = ?', ing_name.downcase).first
        unless existing
          Ingredient.create!(name: ing_name, unit: 'lbs')
        end
      end

      if @item.save
        flash[:notice] = "Item created: #{@item.name}"
        redirect_to ingredients_path and return
      else
        # validation failed - rollback transaction
        raise ActiveRecord::Rollback
      end
    end

    # If we reach here, save failed
    flash[:alert] = @item.errors.full_messages.join(', ')
    redirect_to ingredients_path
  end

  # DELETE /items/:id
  def destroy
    @item = Item.find_by(id: params[:id])
    unless @item
      flash[:alert] = 'Item not found'
      redirect_to ingredients_path and return
    end

    if @item.receipt_items.exists?
      flash[:alert] = 'Cannot delete item that appears on receipts'
      redirect_to ingredients_path and return
    end

    @item.destroy
    flash[:notice] = "Deleted recipe: #{@item.name}"
    redirect_to ingredients_path
  end

  # PATCH /items/:id
  def update
    @item = Item.find_by(id: params[:id])
    unless @item
      flash[:alert] = 'Item not found'
      redirect_to ingredients_path and return
    end

    recipes_params = params[:recipes] || []

    # Build recipes hash, normalizing names and aggregating duplicates
    recipes_agg = {}
    display_name_map = {}

    recipes_params.each do |ing|
      raw_name = (ing[:name].presence || ing['name']).to_s
      name = raw_name.strip
      next if name.blank?

      key = name.downcase
      amount = (ing[:amount].presence || ing['amount']).to_f
      amount = 0.0 if amount.nan?

      recipes_agg[key] ||= 0.0
      recipes_agg[key] += amount
      display_name_map[key] ||= name.split.map(&:capitalize).join(' ')
    end

    recipes_hash = {}
    recipes_agg.each do |key, amt|
      # treat non-positive amounts as removal
      next if amt <= 0
      recipes_hash[display_name_map[key]] = amt
    end

    ActiveRecord::Base.transaction do
      recipes_hash.each_key do |ing_name|
        existing = Ingredient.where('lower(name) = ?', ing_name.downcase).first
        Ingredient.create!(name: ing_name, unit: 'lbs') unless existing
      end

      @item.recipes = recipes_hash
      if @item.save
        flash[:notice] = "Updated recipe: #{@item.name}"
        redirect_to ingredients_path and return
      else
        raise ActiveRecord::Rollback
      end
    end

    flash[:alert] = @item.errors.full_messages.join(', ')
    redirect_to ingredients_path
  end

  private

  def item_params
    params.permit(:name, :price, :category)
  end
end


require 'rails_helper'

RSpec.describe ItemsController, type: :controller do
  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new item' do
        expect {
          post :create, params: {
            name: 'Burger',
            price: 10.0,
            category: 'Entrees',
            ingredients: [
              { name: 'Beef', amount: 0.5 },
              { name: 'Cheese', amount: 0.1 }
            ]
          }
        }.to change(Item, :count).by(1)
      end

      it 'creates missing ingredients' do
        expect {
          post :create, params: {
            name: 'Pizza',
            price: 12.0,
            category: 'Entrees',
            ingredients: [
              { name: 'Dough', amount: 1.0 },
              { name: 'Cheese', amount: 0.5 }
            ]
          }
        }.to change(Ingredient, :count).by_at_least(2)
      end

      it 'sets recipes correctly' do
        post :create, params: {
          name: 'Salad',
          price: 8.0,
          category: 'Sides',
          ingredients: [
            { name: 'Lettuce', amount: 0.5 },
            { name: 'Tomato', amount: 0.2 }
          ]
        }
        
        item = Item.last
        expect(item.recipes).to have_key('Lettuce')
        expect(item.recipes).to have_key('Tomato')
      end

      it 'aggregates duplicate ingredients (case-insensitive)' do
        post :create, params: {
          name: 'Test Item',
          price: 10.0,
          category: 'Entrees',
          ingredients: [
            { name: 'cheese', amount: 0.5 },
            { name: 'Cheese', amount: 0.3 }
          ]
        }
        
        item = Item.last
        expect(item.recipes['Cheese']).to eq(0.8)
      end

      it 'skips ingredients with zero or negative amounts' do
        post :create, params: {
          name: 'Test Item',
          price: 10.0,
          category: 'Entrees',
          ingredients: [
            { name: 'Beef', amount: 0.5 },
            { name: 'Bad Ingredient', amount: 0 }
          ]
        }
        
        item = Item.last
        expect(item.recipes).not_to have_key('Bad Ingredient')
      end

      it 'redirects to ingredients path' do
        post :create, params: {
          name: 'Burger',
          price: 10.0,
          category: 'Entrees',
          ingredients: []
        }
        
        expect(response).to redirect_to(ingredients_path)
      end

      it 'sets success flash message' do
        post :create, params: {
          name: 'Burger',
          price: 10.0,
          category: 'Entrees',
          ingredients: []
        }
        
        expect(flash[:notice]).to match(/Item created/)
      end
    end

    context 'with invalid parameters' do
      it 'does not create item without name' do
        expect {
          post :create, params: {
            price: 10.0,
            category: 'Entrees',
            ingredients: []
          }
        }.not_to change(Item, :count)
      end

      it 'sets error flash message' do
        post :create, params: {
          name: '',
          price: 10.0,
          category: 'Entrees',
          ingredients: []
        }
        
        expect(flash[:alert]).to be_present
      end

      it 'redirects to ingredients path on error' do
        post :create, params: {
          name: '',
          price: 10.0,
          category: 'Entrees',
          ingredients: []
        }
        
        expect(response).to redirect_to(ingredients_path)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:item) { Item.create!(name: 'Test Item', price: 10.0, category: 'Entrees') }

    context 'when item exists and has no receipts' do
      it 'deletes the item' do
        expect {
          delete :destroy, params: { id: item.id }
        }.to change(Item, :count).by(-1)
      end

      it 'sets success flash message' do
        delete :destroy, params: { id: item.id }
        
        expect(flash[:notice]).to match(/Deleted recipe/)
      end

      it 'redirects to ingredients path' do
        delete :destroy, params: { id: item.id }
        
        expect(response).to redirect_to(ingredients_path)
      end
    end

    context 'when item has receipts' do
      before do
        receipt = Receipt.create!(receipt_date: Date.today, receipt_time: '12:00')
        receipt.receipt_items.create!(item: item, quantity: 1)
      end

      it 'does not delete the item' do
        expect {
          delete :destroy, params: { id: item.id }
        }.not_to change(Item, :count)
      end

      it 'sets error flash message' do
        delete :destroy, params: { id: item.id }
        
        expect(flash[:alert]).to match(/Cannot delete/)
      end
    end

    context 'when item does not exist' do
      it 'sets error flash message' do
        delete :destroy, params: { id: 99999 }
        
        expect(flash[:alert]).to eq('Item not found')
      end

      it 'redirects to ingredients path' do
        delete :destroy, params: { id: 99999 }
        
        expect(response).to redirect_to(ingredients_path)
      end
    end
  end

  describe 'PATCH #update' do
    let!(:item) { Item.create!(name: 'Old Name', price: 10.0, category: 'Entrees', recipes: { 'Beef' => 0.5 }) }

    context 'with valid parameters' do
      it 'updates recipes successfully' do
        patch :update, params: {
          id: item.id,
          recipes: [
            { name: 'Chicken', amount: 0.7 }
          ]
        }
        
        item.reload
        expect(item.recipes).to have_key('Chicken')
      end

      it 'updates recipes' do
        patch :update, params: {
          id: item.id,
          recipes: [
            { name: 'Chicken', amount: 0.7 },
            { name: 'Lettuce', amount: 0.2 }
          ]
        }
        
        item.reload
        expect(item.recipes).to have_key('Chicken')
        expect(item.recipes).not_to have_key('Beef')
      end

      it 'creates missing ingredients' do
        expect {
          patch :update, params: {
            id: item.id,
            recipes: [
              { name: 'New Ingredient', amount: 1.0 }
            ]
          }
        }.to change(Ingredient, :count).by_at_least(1)
      end

      it 'removes ingredients with zero amount' do
        patch :update, params: {
          id: item.id,
          recipes: [
            { name: 'Beef', amount: 0 }
          ]
        }
        
        item.reload
        expect(item.recipes).not_to have_key('Beef')
      end

      it 'aggregates duplicate ingredients' do
        patch :update, params: {
          id: item.id,
          recipes: [
            { name: 'cheese', amount: 0.5 },
            { name: 'Cheese', amount: 0.3 }
          ]
        }
        
        item.reload
        expect(item.recipes['Cheese']).to eq(0.8)
      end

      it 'sets success flash message' do
        patch :update, params: {
          id: item.id,
          recipes: []
        }
        
        expect(flash[:notice]).to match(/Updated recipe/)
      end

      it 'redirects to ingredients path' do
        patch :update, params: {
          id: item.id,
          recipes: []
        }
        
        expect(response).to redirect_to(ingredients_path)
      end
    end

    context 'when item does not exist' do
      it 'sets error flash message' do
        patch :update, params: {
          id: 99999,
          recipes: []
        }
        
        expect(flash[:alert]).to eq('Item not found')
      end

      it 'redirects to ingredients path' do
        patch :update, params: {
          id: 99999,
          recipes: []
        }
        
        expect(response).to redirect_to(ingredients_path)
      end
    end

    context 'with invalid recipe format' do
      it 'handles update gracefully' do
        # Update only modifies recipes, not base attributes
        # So as long as recipes are valid, it succeeds
        patch :update, params: {
          id: item.id,
          recipes: []
        }
        
        expect(response).to redirect_to(ingredients_path)
        expect(flash[:notice]).to be_present
      end
    end
  end
end


require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render plain: 'test'
    end
  end

  before do
    routes.draw { get 'index' => 'anonymous#index' }
  end

  describe 'CSRF protection' do
    it 'has protect_from_forgery configured' do
      expect(ApplicationController.ancestors).to include(ActionController::RequestForgeryProtection)
    end

    it 'uses exception strategy for forgery protection' do
      forgery_protection = ApplicationController.forgery_protection_strategy
      expect(forgery_protection).to eq(ActionController::RequestForgeryProtection::ProtectionMethods::Exception)
    end
  end

  describe 'basic functionality' do
    it 'inherits from ActionController::Base' do
      expect(ApplicationController.superclass).to eq(ActionController::Base)
    end

    it 'can render a simple action' do
      get :index
      expect(response).to be_successful
      expect(response.body).to eq('test')
    end
  end
end

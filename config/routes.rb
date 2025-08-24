Rails.application.routes.draw do
  scope module: 'api', as: 'api', path: '/api' do
    namespace :v1 do
      namespace :followings do
        get 'sleep_ranking', to: 'sleep_rankings#index'
      end
      
      resources :follows, only: [:create, :destroy]
      namespace :sleep_records do
        resource :clock_in, only: [:create]
      end
    end
  end
end

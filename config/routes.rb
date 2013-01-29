LantanBAM::Application.routes.draw do
  root :to => 'logins#index'
  resources :logins  
  resources :stores do
    resources :welcomes
    resources :customers
    resources :materials
  end

  resources :materials do
    member do
       get "remark"
    end

    collection do
       get "out"
    end
  end


end

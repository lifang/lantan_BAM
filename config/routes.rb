LantanBAM::Application.routes.draw do
  root :to => 'logins#index'
  resources :logins  
  resources :stores do
    resources :welcomes
    resources :customers do
      collection do
        post "search"
        get "search_list"
      end
    end
    resources :revisits do
      collection do
        post "search"
        get "search_list"
      end
    end
    resources :messages do
      collection do
        post "search"
        get "search_list"
      end
    end
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

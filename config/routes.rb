LantanBAM::Application.routes.draw do
  resources :sales
  resources :stations
  # The priority is based upon order of creation:
  # first created -> highest priority.
  root :to => 'logins#index'
  resources :logins
  resources :stores do
    resources :sales
    resources :materials do
      collection do
        get "out","search","order"
        post "out_order","material_order","add"
      end
    end

    resources :suppliers
    resources :welcomes
    resources :customers do
      collection do
        post "search", "customer_mark", "single_send_message"
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
  end

  resources :materials do
    member do
      get "remark","check"
    end
    collection do
      get "get_act_count", "out"
    end
  end

end

LantanBAM::Application.routes.draw do

  resources :stores do
    resources :materials do
      collection do
        get "out","search","order"
        post "out_order","material_order","add"
      end
    end

    resources :suppliers do
       member do

       end
    end
  end

  resources :materials do
    member do
       get "remark","check"
    end
    collection do
      get "get_act_count"
    end
  end

  resources :suppliers do

  end

end

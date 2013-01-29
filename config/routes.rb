LantanBAM::Application.routes.draw do

  resources :stores do
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

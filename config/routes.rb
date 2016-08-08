Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root 'tabs#show', id: 'about'
  resources :tabs

  resource :streaming, controller: 'streaming'


end

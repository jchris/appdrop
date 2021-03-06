ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # See how all your routes lay out with "rake routes"

  map.resources :apps, :member => {:manage => :get, :upload => :post}

  map.root :controller => "pages"

  map.connect 'login', :controller => 'login', :action => 'login', 
    :conditions => {:method => :get}

  map.connect '/login', :controller => 'login', :action => 'create', 
    :conditions => {:method => :post}

  map.connect '/login', :controller => 'login', :action => 'destroy', 
    :conditions => {:method => :delete}

  map.connect '/authorize', :controller => 'login', :action => 'authorize'
  map.connect '/auth', :controller => 'login', :action => 'auth'
  
  # Install the default routes as the lowest priority.
  # map.connect ':controller/:action/:id'
  # map.connect ':controller/:action/:id.:format'
end

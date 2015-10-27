# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

#get 'scheduling_polls', :to => 'scheduling_polls#index'
get 'scheduling_polls/:id/show', :to => 'scheduling_polls#show'

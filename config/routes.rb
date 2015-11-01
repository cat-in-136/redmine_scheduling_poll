# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

#get 'scheduling_polls', :to => 'scheduling_polls#index'
get 'scheduling_polls/:id/show', :to => 'scheduling_polls#show', :as => 'scheduling_poll'
post 'scheduling_polls/:id/vote', :to => 'scheduling_polls#vote'
get 'scheduling_polls/new', :to => 'scheduling_polls#new', :as => 'scheduling_polls_new'
post 'scheduling_polls/create', :to => 'scheduling_polls#create', :as => 'scheduling_polls_create'

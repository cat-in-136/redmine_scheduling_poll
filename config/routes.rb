# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

#get 'scheduling_polls', :to => 'scheduling_polls#index'
get 'scheduling_polls/new', :to => 'scheduling_polls#new', :as => 'scheduling_polls_new'
post 'scheduling_polls/create', :to => 'scheduling_polls#create', :as => 'scheduling_polls_create'
get 'scheduling_polls/:id/edit', :to => 'scheduling_polls#edit', :as => 'scheduling_poll_edit'
#post 'scheduling_polls/:id/update', :to => 'scheduling_polls#update'
patch 'scheduling_polls/:id/update', :to => 'scheduling_polls#update'
get 'scheduling_polls/:id/show', :to => 'scheduling_polls#show', :as => 'scheduling_poll'
get 'scheduling_polls/show_by_issue/:issue_id', :to => 'scheduling_polls#show_by_issue', :as => 'scheduling_poll_show_by_issue'
post 'scheduling_polls/:id/vote', :to => 'scheduling_polls#vote'

Rails.application.routes.draw do
  devise_for :users
  # This is a blank app! Pick your first screen, build out the RCAV, and go from there. E.g.:
  # get("/your_first_screen", { :controller => "pages", :action => "first" })

  get("/", { :controller => "movies", :action => "index"})
  get("/movies", { :controller => "movies", :action => "index"})
  get("/movies/:id", { :controller => "movies", :action => "show"})

  get("/watchlist", {:controller => "watchlist_items", :action => "index"})
  get("/seen", {:controller => "watchlist_items", :action => "seen"})

  post("/insert_watchlist_item", {:controller => "watchlist_items", :action => "create"})
  post("/mark_seen", {:controller => "watchlist_items", :action => "mark_seen"})
  post("/remove_from_watchlist", {:controller => "watchlist_items", :action => "remove"})
end

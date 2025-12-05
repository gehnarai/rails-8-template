Rails.application.routes.draw do
  devise_for :users
  # This is a blank app! Pick your first screen, build out the RCAV, and go from there. E.g.:
  # get("/your_first_screen", { :controller => "pages", :action => "first" })

  get "/", controller: "movies", action: "index"
  get "/movies", controller: "movies", action: "index"
  get "/movies/:id", controller: "movies", action: "show"
end

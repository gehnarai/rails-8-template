class MoviesController < ApplicationController
  def index
    api_key = ENV["TMDB_API_KEY"]

    response = HTTParty.get(
      "https://api.themoviedb.org/3/trending/movie/week",
      query: {
        api_key: api_key,
        language: "en-US"
      }
    )
    @movies = response["results"] || []
     render({ :template => "movies_templates/index" })

  end
end

class MoviesController < ApplicationController
  def index
    api_key = ENV["TMDB_API_KEY"]

     base_url = "https://api.themoviedb.org/3"

    min_rating  = params[:min_rating]
    max_runtime = params[:max_runtime]

    if min_rating.present? || max_runtime.present?
      # Use /discover/movie when any filter is present
      response = HTTParty.get(
        "#{base_url}/discover/movie",
        query: {
          api_key: api_key,
          language: "en-US",
          sort_by: "popularity.desc",
          "vote_average.gte": min_rating,
          "with_runtime.lte": max_runtime
          # later we’ll add: with_genres, with_watch_providers, etc.
        }.compact  # drops nil values
      )
    else
      # default: trending
      response = HTTParty.get(
        "#{base_url}/discover/movie",
        query: {
          api_key: api_key,
          language: "en-US"
        }
      )
    end

    @movies = response["results"] || []

    render({:template => "movies_templates/index"})
  end
end

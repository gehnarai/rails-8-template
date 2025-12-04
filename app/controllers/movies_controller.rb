class MoviesController < ApplicationController
    PROVIDER_IDS = {
    "netflix" => 8, 
    "prime"   => 9,
    "disney"  => 337,
    "hulu"    => 15 
  }.freeze

  def index
    api_key = ENV["TMDB_API_KEY"]

     base_url = "https://api.themoviedb.org/3"

    min_rating  = params[:min_rating]
    max_runtime = params[:max_runtime]
    genre_id    = params[:genre_id]
    query       = params[:query]
    provider    = params[:provider]

      filters_present = [
      min_rating,
      max_runtime,
      genre_id,
      query,
      provider
    ].any?(&:present?)

    unless filters_present
      @movies = []
      return render template: "movies_templates/index"
    end

     if query.present?
      # 🔎 Search by title – TMDB /search/movie
      response = HTTParty.get(
        "#{base_url}/search/movie",
        query: {
          api_key: api_key,
          language: "en-US",
          query: query,
          include_adult: false
        }
      )
    else
      # 🎛 Filtered discover – TMDB /discover/movie
      discover_query = {
        api_key: api_key,
        language: "en-US",
        sort_by: "popularity.desc",
        include_adult: false
      }

      discover_query[:"vote_average.gte"] = min_rating  if min_rating.present?
      discover_query[:"with_runtime.lte"] = max_runtime if max_runtime.present?
      discover_query[:with_genres]       = genre_id     if genre_id.present?

      if provider.present?
        provider_id = PROVIDER_IDS[provider]
        if provider_id
          discover_query[:with_watch_providers] = provider_id
        end
      end

      response = HTTParty.get("#{base_url}/discover/movie", query: discover_query)
    end

    @movies = response["results"] || []

    render({:template => "movies_templates/index"})
  end
end

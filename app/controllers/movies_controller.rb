class MoviesController < ApplicationController

  # require sign in for movie details page 
  before_action :authenticate_user!, only: [:show]

  REGION = "US".freeze # provider_ids are region specific to keeping it to US only

  PROVIDER_IDS = {
    "netflix" => 8,
    "prime" => 9,
    "disney" => 337,
    "hulu" => 15,
    "apple_tv" => 2,
    "hbo_max" => 1899
  }.freeze

  def index
    api_key = ENV["TMDB_API_KEY"]

    base_url = "https://api.themoviedb.org/3"

    filter_keys = %w[min_rating max_runtime genre_id query provider]

    # to detect if form has ever been submitted
    form_submitted = filter_keys.any? { |k| params.key?(k) }

    # First visit / hard refresh with no query string: just show the form
    unless form_submitted
      @movies = []
      @suggestion_message = nil
      return render template: "movies_templates/index"
    end

    min_rating = params[:min_rating]
    max_runtime = params[:max_runtime]
    genre_id = params[:genre_id]
    query = params[:query]
    provider = params[:provider]

    filters_present = [
      min_rating,
      max_runtime,
      genre_id,
      query,
      provider,
    ].any?(&:present?)

       if !filters_present
      # if no fields field, show a default recommendations list
      response = HTTParty.get(
        "#{base_url}/discover/movie",
        query: {
          api_key: api_key,
          language: "en-US",
          sort_by: "vote_average.desc",   # highest rated first
          "vote_count.gte": 1000,         # to avoid weird obscure stuff
          include_adult: false,
          watch_region: REGION 
        }
      )

      @movies = response["results"] || []
      @suggestion_message = "Looks like you're not picky today, so here are some top movies for you 🍿"
    else
    if query.present?
      # Search by title
      response = HTTParty.get(
        "#{base_url}/search/movie",
        query: {
          api_key: api_key,
          language: "en-US",
          query: query,
          include_adult: false,
          watch_region: REGION 
        },
      )
    else
      # Discover with filters
      discover_query = {
        api_key: api_key,
        language: "en-US",
        sort_by: "popularity.desc",
        include_adult: false,
      }

      discover_query[:"vote_average.gte"] = min_rating if min_rating.present?
      discover_query[:"with_runtime.lte"] = max_runtime if max_runtime.present?
      discover_query[:with_genres] = genre_id if genre_id.present?

      if provider.present?
        provider_id = PROVIDER_IDS[provider]
        if provider_id
          discover_query[:with_watch_providers] = provider_id
          discover_query[:watch_region]         = REGION
          discover_query[:with_watch_monetization_types] = "flatrate|ads|free|rent|buy"
        end
      end


      response = HTTParty.get("#{base_url}/discover/movie", query: discover_query)
    end

    @movies = response["results"] || []
  end

    # 🔍 Extra AND-filtering when a title is present
    if query.present?
      @movies.select! do |m|
        ok = true

        # filter by rating if provided
        if min_rating.present?
          ok &&= m["vote_average"].to_f >= min_rating.to_f
        end

        # filter by genre if provided (search results include genre_ids)
        if genre_id.present?
          ok &&= (m["genre_ids"] || []).include?(genre_id.to_i)
        end

        # NOTE: runtime & provider filters are *not* applied here,
        # because /search/movie results don't include runtime or providers.
        # (We'd need extra API calls per movie to do that.)

        ok
      end
    end

    sort = params[:sort].presence || "rating"  # default: rating desc

    case sort
    when "title"
      @movies.sort_by! { |m| (m["title"] || "").downcase }
    when "release_date"
      @movies.sort_by! { |m| m["release_date"] || "" }.reverse!  # newest first
    else # "rating"
      @movies.sort_by! { |m| m["vote_average"] || 0 }.reverse!   # highest rating first
    end

    render({ :template => "movies_templates/index" })
  end

  def show
    api_key = ENV["TMDB_API_KEY"]
    movie_id = params[:id]
    base_url = "https://api.themoviedb.org/3"
    region   = "US"  # to update to region toggle

    # Main movie details
    detail_response = HTTParty.get(
      "#{base_url}/movie/#{movie_id}",
      query: {
        api_key: api_key,
        language: "en-US",
      },
    )

    # Cast / credits
    credits_response = HTTParty.get(
      "#{base_url}/movie/#{movie_id}/credits",
      query: {
        api_key: api_key,
        language: "en-US",
      },
    )

    # Where to watch
    providers_response = HTTParty.get(
      "#{base_url}/movie/#{movie_id}/watch/providers",
      query: {
        api_key: api_key,
      },
    )

    @movie = detail_response.parsed_response

    # Top 5 cast members
    @cast = (credits_response.parsed_response["cast"] || []).first(5)

    # Streaming

    providers_response = HTTParty.get(
      "#{base_url}/movie/#{movie_id}/watch/providers",
      query: { api_key: api_key },
    )

    region_data = providers_response.parsed_response.dig("results", REGION) || {}
    @streaming = {
      flatrate:  (region_data["flatrate"] || []) + (region_data["ads"] || []) + (region_data["free"] || []),
      rent: region_data["rent"] || [],
      buy: region_data["buy"] || [],
    }

    render({ :template => "movies_templates/show" })
  end
end

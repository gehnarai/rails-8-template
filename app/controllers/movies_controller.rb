class MoviesController < ApplicationController
  PROVIDER_IDS = {
    "netflix" => 8,
    "prime" => 9,
    "disney" => 337,
    "hulu" => 15,
  }.freeze

  def index
    api_key = ENV["TMDB_API_KEY"]

    base_url = "https://api.themoviedb.org/3"

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
          include_adult: false,
        },
      )
    else
      # 🎛 Filtered discover – TMDB /discover/movie
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
        end
      end

      response = HTTParty.get("#{base_url}/discover/movie", query: discover_query)
    end

    @movies = response["results"] || []
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
    region = params[:region].presence || "US"

    providers_response = HTTParty.get(
      "#{base_url}/movie/#{movie_id}/watch/providers",
      query: { api_key: api_key },
    )

    us_providers = providers_response.parsed_response.dig("results", region) || {}
    @streaming = {
      flatrate: us_providers["flatrate"] || [],
      rent: us_providers["rent"] || [],
      buy: us_providers["buy"] || [],
    }

    render({ :template => "movies_templates/show" })
  end
end

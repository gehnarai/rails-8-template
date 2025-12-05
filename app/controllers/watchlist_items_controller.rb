class WatchlistItemsController < ApplicationController
  before_action :authenticate_user!

  REGION   = "US".freeze
  BASE_URL = "https://api.themoviedb.org/3".freeze

  def create
    api_key = ENV["TMDB_API_KEY"]
    tmdb_id = params[:tmdb_id]
    return redirect_back fallback_location: "/", alert: "Missing movie id." if tmdb_id.blank?

    # either find existing or build new
    item = current_user.watchlist_items.find_or_initialize_by(tmdb_id: tmdb_id)
    item.seen = false

    if item.save
      redirect_to "/watchlist", notice: "Added to your watchlist."
    else
      redirect_back fallback_location: "/", alert: "Could not add to watchlist."
    end
  end

  def mark_seen
    tmdb_id = params[:tmdb_id]
    return redirect_back fallback_location: "/", alert: "Missing movie id." if tmdb_id.blank?

    item = current_user.watchlist_items.find_or_initialize_by(tmdb_id: tmdb_id)
    item.seen = true

    if item.save
      redirect_to "/seen", notice: "Marked as seen."
    else
      redirect_back fallback_location: "/", alert: "Could not update movie."
    end
  end

  def index
    api_key = ENV["TMDB_API_KEY"]

    # only UNSEEN items
    @watchlist_items = current_user.watchlist_items.where(seen: false)

    @movies = @watchlist_items.map do |item|
      response = HTTParty.get(
        "#{BASE_URL}/movie/#{item.tmdb_id}",
        query: {
          api_key: api_key,
          language: "en-US"
        }
      )
      response.parsed_response
    end

    render({:template => "watchlist_items/index"})
  end

  def seen
    api_key = ENV["TMDB_API_KEY"]

    # only SEEN items
    @seen_items = current_user.watchlist_items.where(seen: true)

    @movies = @seen_items.map do |item|
      response = HTTParty.get(
        "#{BASE_URL}/movie/#{item.tmdb_id}",
        query: {
          api_key: api_key,
          language: "en-US"
        }
      )
      response.parsed_response
    end

    render({:template => "watchlist_items/seen"})
  end
end

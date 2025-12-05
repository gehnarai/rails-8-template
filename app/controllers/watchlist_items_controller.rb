class WatchlistItemsController < ApplicationController
  before_action :authenticate_user!

  REGION = "US".freeze
  BASE_URL = "https://api.themoviedb.org/3".freeze

  def create
    api_key = ENV["TMDB_API_KEY"]
    tmdb_id = params[:tmdb_id]
    return redirect_back fallback_location: "/", alert: "Missing movie id." if tmdb_id.blank?

    # either find existing or build new
    item = current_user.watchlist_items.find_or_initialize_by(tmdb_id: tmdb_id)
    item.seen = false

    if item.save
      redirect_back fallback_location: "/",
                    notice: "Added to your <a href ='/watchlist'>watchlist! </a>"
    else
      redirect_back fallback_location: "/",
                    alert: "Something went wrong. Please try again."
    end
  end

  def mark_seen
    tmdb_id = params[:tmdb_id]
    return redirect_back fallback_location: "/", alert: "Missing movie id." if tmdb_id.blank?

    item = current_user.watchlist_items.find_or_initialize_by(tmdb_id: tmdb_id)
    item.seen = true

    if item.save
      redirect_back fallback_location: "/",
                    notice: "Added to your <a href='/seen'>watched archive!</a>"
    else
      redirect_back fallback_location: "/",
                    alert: "Something went wrong. Please try again."
    end
  end

  def index
    api_key = ENV["TMDB_API_KEY"]

    # only UNSEEN items
    @watchlist_items = current_user.watchlist_items.where(seen: false).order(created_at: :asc)

    @rows = @watchlist_items.map do |item|
      response = HTTParty.get(
        "#{BASE_URL}/movie/#{item.tmdb_id}",
        query: {
          api_key: api_key,
          language: "en-US",
        },
      )
      {
        item: item,                    # for created_at, id, etc.
        movie: response.parsed_response, # TMDB data
      }
    end

    render({ :template => "watchlist_items/index" })
  end

  def seen
    api_key = ENV["TMDB_API_KEY"]

    # only SEEN items
    @seen_items = current_user.watchlist_items.where(seen: true).order(updated_at: :desc)

    @rows = @seen_items.map do |item|
      response = HTTParty.get(
        "#{BASE_URL}/movie/#{item.tmdb_id}",
        query: {
          api_key: api_key,
          language: "en-US",
        },
      )
      {
        item: item,
        movie: response.parsed_response,
      }
    end

    render({ :template => "watchlist_items/seen" })
  end

  def remove
    tmdb_id = params[:tmdb_id]

    item = current_user.watchlist_items.find_by(tmdb_id: tmdb_id, seen: false)

    if item
      item.destroy
      redirect_back fallback_location: "/watchlist",
                    notice: "Removed from your watchlist."
    else
      redirect_back fallback_location: "/watchlist",
                    alert: "Could not find that movie in your watchlist."
    end
  end

  def remove_from_seen
    tmdb_id = params[:tmdb_id]

    item = current_user.watchlist_items.find_by(tmdb_id: tmdb_id, seen: true)

    if item
      item.destroy
      redirect_to "/seen", notice: "Removed from your seen archive."
    else
      redirect_to "/seen", alert: "Couldn’t find that movie in your seen archive."
    end
  end
end

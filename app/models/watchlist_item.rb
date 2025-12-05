# == Schema Information
#
# Table name: watchlist_items
#
#  id         :bigint           not null, primary key
#  seen       :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  tmdb_id    :integer
#  user_id    :bigint           not null
#
# Indexes
#
#  index_watchlist_items_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class WatchlistItem < ApplicationRecord
  belongs_to :user

  validates :tmdb_id, presence: true
  validates :user_id, presence: true
  validates :tmdb_id, uniqueness: { scope: :user_id }
end

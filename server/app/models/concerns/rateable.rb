module Rateable
  extend ActiveSupport::Concern

  included do
    validates :average_rating, numericality: {
      less_than_or_equal_to: 5,
      greater_than: 0
    }, allow_nil: true
  end

  def calculate_rating_frequencies
    base = LibraryEntry::VALID_RATINGS.map { |r| [r, 0] }.to_h
    freqs = LibraryEntry.where(media: self).group(:rating).count.
      transform_keys(&:to_f).slice(*LibraryEntry::VALID_RATINGS)
    base.merge(freqs)
  end

  def calculate_rating_frequencies!
    self.update_attribute(:rating_frequencies, calculate_rating_frequencies)
  end

  def update_rating_frequency(rating, diff)
    return if rating.nil?
    update_query = <<-EOF
      rating_frequencies = rating_frequencies
        || hstore('#{rating.to_s}', (
          COALESCE(rating_frequencies->'#{rating}', '0')::integer + #{diff}
        )::text)
    EOF
    self.class.where(id: self.id).update_all(update_query)
    self.touch
  end

  def decrement_rating_frequency(rating)
    update_rating_frequency(rating, -1)
  end

  def increment_rating_frequency(rating)
    update_rating_frequency(rating, +1)
  end
end

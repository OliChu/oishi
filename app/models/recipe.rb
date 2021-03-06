class Recipe < ApplicationRecord
  include Rails.application.routes.url_helpers

  has_many :measures, dependent: :destroy
  has_many :steps, dependent: :destroy
  has_many :ingredients, through: :measures
  has_and_belongs_to_many :tags
  has_and_belongs_to_many :tools
  belongs_to :user
  has_one_attached :image

  validates :name, presence: true, uniqueness: true
  validates :preparation_time, presence: true
  validates :difficulty, presence: true, inclusion: { in: %w(Facile Moyen Difficile),
    message: "%{value} is not a valid difficulty" }

  scope :visible, -> { where(visible: true) }
  scope :recommended, -> { where(recommended: true) }

  include PgSearch

  pg_search_scope :pg_search,
    against: :name,
    associated_against: {
      ingredients: :name,
      tags: :name
    },
    using: {
      tsearch: { prefix: true }
    }

  before_save :update_slug

  def visible?
    visible
  end

  def recommended?
    recommended
  end

  def self.search(query)
    return recommended if query == ''

    safe_query = ActionController::Base.helpers.sanitize(query).strip
    pg_search(safe_query).visible
  end

  def serialize
    image_url = rails_blob_url(self.image) if self.image.attached?
    {
      id: id,
      cooking_time: cooking_time,
      preparation_time: preparation_time,
      difficulty: difficulty,
      servings: servings,
      name: name,
      image_url: image_url,
      slug: slug
    }
  end

  def serialize_recipes_index
    {
      id: id,
      cooking_time: cooking_time,
      preparation_time: preparation_time,
      difficulty: difficulty,
      servings: servings,
      tags: tags.pluck(:name),
      name: name,
      slug: slug
    }
  end

  private

  def update_slug
    return unless name_changed?

    self.slug = I18n.transliterate(name).downcase.split.join('-')
  end
end

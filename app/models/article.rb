class Article < ApplicationRecord
  # if article is deleted, delete comments as well
  has_many :comments, dependent: :destroy
  # ensure that all articles have a title that is 
  # at least five characters long
  validates :title, presence: true,
                    length: {minimum: 5}
  validates :text, presence: true,
                   length: {minimum: 100}
end

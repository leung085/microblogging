class Micropost < ActiveRecord::Base
  belongs_to :user
  validates :user_id, presence: true
  validates :content, length: {maximum: 140}, presence: true
  default_scope -> {order(created_at: :desc)}
  mount_uploader :picture, PictureUploader
  validate :picture_size # use singular because it is a custom validation
  
  def picture_size
    if picture.size > 5.megabytes
      errors.add(:picture, " should be less than 5MB")
    end
  end
end

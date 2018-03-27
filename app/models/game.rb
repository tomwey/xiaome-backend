class Game < ActiveRecord::Base
  validates :name, :icon, :bundle_id, :code, presence: true
  mount_uploader :icon, AvatarUploader
end

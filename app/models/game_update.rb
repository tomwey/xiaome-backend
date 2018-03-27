class GameUpdate < ActiveRecord::Base
  validates :game_id, :version, :os, :search_paths, presence: true
  
  belongs_to :game
  
  mount_uploader :package_file, AppFileUploader
  
  before_validation :update_data_attributes

  private

  def update_data_attributes
    if package_file.present? && package_file_changed?
      self.file_md5  = package_file.md5
    end
  end
    
end

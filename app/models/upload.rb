class Upload < ActiveRecord::Base
  has_attachment :storage => :file_system, :path_prefix => 'uploads'
  belongs_to :user
  belongs_to :app
  
  after_create :send_to_app_once
  
  def send_to_app_once
    return if @sent
    app.update_code self.public_filename
    @sent = true
  end
  
end

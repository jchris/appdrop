class AuthToken < ActiveRecord::Base
  belongs_to :user
  belongs_to :app
  validates_presence_of :user_id
  validates_presence_of :app_id
  validates_presence_of :token
  include TokenGenerator
  before_validation_on_create :set_token
end

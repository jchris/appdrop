# == Schema Information
# Schema version: 2
#
# Table name: users
#
#  id                        :integer       not null, primary key
#  login                     :string(255)   
#  email                     :string(255)   
#  crypted_password          :string(40)    
#  salt                      :string(40)    
#  created_at                :datetime      
#  updated_at                :datetime      
#  last_login_at             :datetime      
#  remember_token            :string(255)   
#  remember_token_expires_at :datetime      
#  visits_count              :integer       default(0)
#  time_zone                 :string(255)   default("Etc/UTC")
#

require 'digest/sha1'
class User < ActiveRecord::Base
  include AuthenticatedBase
  # has_many :images, :as => :attachable

  # composed_of :tz, :class_name => 'TZInfo::Timezone', :mapping => %w( time_zone time_zone )
  validates_presence_of     :email
  validates_format_of :nickname, :with => /\A[\-a-z0-9A-Z\s]*\Z/
  validates_format_of :email, :with => /^[_\w\d+-]+(\.[_\w\d-]+)*@[^\.@][\w\d\.-]+$/

  validates_uniqueness_of :email, :case_sensitive => false

  # Protect internal methods from mass-update with update_attributes
  attr_accessible :nickname, :email, :password, :password_confirmation, :time_zone
  include TokenGenerator
  before_create :set_upload_token
  
  def set_upload_token
    set_token(24)
  end
  
  def to_param
    email
  end

  def to_s
    nickname || email
  end

  def self.find_by_param(*args)
    find_by_email *args
  end

  def to_xml
    super( :only => [ :email, :nickname, :last_login_at ] )
  end

end

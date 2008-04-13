require 'ftools'

class App < ActiveRecord::Base

  validates_uniqueness_of :key
  validates_uniqueness_of :port
  validates_presence_of :key
  validates_presence_of :port
  validates_presence_of :user_id
  validates_format_of   :key, :with => /\A[\-a-z0-9]*\Z/
  validates_length_of   :key, :in => (1..32)
  validates_inclusion_of :port, :in => (3000..65535)
  
  belongs_to :user
  
  def initialize_configuration
    make_app_dirs
    create_portfile
    nginx_config
  end
  
  def make_app_dirs
    File.makedirs "/var/apps/#{key}/app", "/var/apps/#{key}/data", "/var/apps/#{key}/log"
  end
  
  def create_portfile
    File.open("/var/apps/#{key}/portfile",'w') do |f|
      f.write port
    end
  end
  
  def nginx_config
    conf = <<-NGINX
    server {
      listen   80;
      server_name  #{key}.appdrop.com;
      access_log  /var/apps/#{key}/log/access.log;
      location / {
        proxy_set_header  X-Real-IP  $remote_addr;
        proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_redirect false;
        proxy_pass http://localhost:#{port};
      }
    }
    NGINX
    File.open("/etc/nginx/sites-enabled/#{key}",'w') do |f|
      f.write(conf)
    end
  end
  
end

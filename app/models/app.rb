require 'ftools'

class App < ActiveRecord::Base

  APP_ROOT = "/var/apps"
  class FileError < StandardError; end;

  validates_uniqueness_of :key
  validates_uniqueness_of :port
  validates_presence_of :key
  # validates_presence_of :port
  validates_presence_of :user_id
  validates_format_of   :key, :with => /\A[\-a-z0-9]*\Z/
  validates_length_of   :key, :in => (1..32)
  validates_inclusion_of :port, :in => (3000..65535), :allow_nil => true
  
  belongs_to :user
  
  after_create :do_setup
  
  def to_param
    key
  end
  
  def do_setup
    set_port
    initialize_configuration
  end
  
  def set_port
    return if self.port
    transaction do
      a = App.find :first, :order => 'port desc', :conditions => ['id != ?', self.id]
      self.update_attribute :port, a.port + 1
    end
  end
  
  def initialize_configuration
    make_app_dirs
    create_portfile
    nginx_config
  end
  
  def update_code(tarfile)
    untar_to_tmpdir(tarfile)
    fileappkey = validate_appfiles
    raise FileError, "Invalid application key in tarfile" unless fileappkey == self.key
    replace_app_with_new
  end

  def replace_app_with_new
    tmpdir = "#{APP_ROOT}/#{key}/tmpapp"
    appdir = "#{APP_ROOT}/#{key}/app"
    # File.copy(tmpdir, appdir)
    `rm -rf #{appdir}`
    `mv #{tmpdir} #{appdir}`
  end

  def untar_to_tmpdir(tarfile)
    tmpdir = "#{APP_ROOT}/#{key}/tmpapp"
    `rm -rf #{tmpdir}`
    File.makedirs tmpdir
    tarc = "tar --file #{tarfile} --force-local -C #{tmpdir} -zx"
    success = system(tarc)
    raise  FileError, "Filesystem error with #{tarc}" unless success
  end
  
  def validate_appfiles
    tmpdir = "#{APP_ROOT}/#{key}/tmpapp"
    yamls = ["#{tmpdir}/app.yaml", "#{tmpdir}/app.yml"]
    appid = nil
    unless yamls.any? do |file|
      if File.exists?(file)
        parse = File.open(file) { |yf| YAML::load( yf ) }        
        appid = parse['application'] if parse['application']
      end
    end
      raise FileError, "Directory #{tmpdir} does not contain a valid app.yaml or app.yml"
    end
    return appid
  end
  
  def make_app_dirs
    File.makedirs "#{APP_ROOT}/#{key}/app", "#{APP_ROOT}/#{key}/data", "#{APP_ROOT}/#{key}/log", "#{APP_ROOT}/#{key}/tmpapp"
  end
  
  def create_portfile
    File.open("#{APP_ROOT}/#{key}/portfile",'w') do |f|
      f.write port
    end
  end
  
  def nginx_config
    conf = <<-NGINX
    server {
      listen   80;
      server_name  #{key}.appdrop.com;
      access_log  #{APP_ROOT}/#{key}/log/access.log;
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

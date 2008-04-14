require 'ftools'

class App < ActiveRecord::Base

  APP_ROOT = "/var/apps"
  class FileError < StandardError; end;

  validates_uniqueness_of :key
  validates_uniqueness_of :port
  validates_presence_of :key
  validates_presence_of :user_id
  validates_format_of   :key, :with => /\A[\-a-z0-9]*\Z/
  validates_length_of   :key, :in => (1..32)
  validates_inclusion_of :port, :in => (3000..65535), :allow_nil => true
  
  belongs_to :user
  has_many :uploads
  
  after_create :do_setup
  
  def to_param
    key
  end
  
  def ready?
    self.state == "ready"
  end
  
  def do_setup
    set_port
    initialize_configuration
  end
  
  def set_port
    return if self.port
    transaction do
      a = App.find :first, :order => 'port desc', :conditions => ['id != ?', self.id]
      myport = a ? a.port + 1 : 4000
      self.update_attribute :port, myport
    end
  end
  
  def initialize_configuration
    make_app_dirs
    create_portfile
    set_apps_permissions
    nginx_config
    reload_nginx
    god_config
  end
  
  def update_code(tarfile)
    untar_to_tmpdir(tarfile)
    fileappkey = validate_appfiles
    raise FileError, "Invalid application key in tarfile" unless fileappkey == self.key
    replace_app_with_new
    set_apps_permissions
    load_god_conf # starts and keeps app up
    self.update_attribute(:state, "ready")
  end

  def set_apps_permissions
    Kernel.system("chown -R apps /var/apps/")
  end

  def reload_nginx
    Kernel.system("/etc/init.d/nginx reload")
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
    set_apps_permissions
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
  
  def load_god_conf
    Kernel.system "/usr/bin/god load /var/local/god/#{key}.god"
  end
  
  def god_config
    conf = <<-GOD
      God.watch do |w|
        w.group = "apps"
        w.name = "app-#{key}"
        w.uid = 'apps'
        w.gid = 'apps'
        w.interval = 30.seconds
        w.start = "/root/packages/appdrop_appengine/dev_appserver.py -p #{port} --datastore_path=/var/apps/#{key}/data/app.datastore --history_path=/var/apps/#{key}/data/app.datastore.history /var/apps/#{key}/app >> /var/apps/#{key}/log/server.log 2>&1"
        w.start_grace = 10.seconds
        w.start_if do |start|
          start.condition(:process_running) do |c|
            c.interval = 10.seconds
            c.running = false
            c.notify = 'jchris'
          end
        end
      end
    GOD
    File.open("/var/local/god/#{key}.god",'w') do |f|
      f.write(conf)
    end
  end
  
end

require 'yaml'

class AppdropUpload
  class FileError < StandardError; end;
  class UploadError < StandardError; end;
  def self.process args
    uploader = new :appdir => args[0]
    uploader.run
  end
  def initialize opts
    @appdir = opts[:appdir]
  end
  def run
    create_tarfile
    acquire_token
  end

  def create_tarfile
    @appid = validate_appdir
    cstring = "tar -czf /tmp/#{@appid}.tar.gz -C #{@appdir} ."
    success = Kernel.system(cstring)
    unless success
      raise FileError, "Error creating tarfile. Does the directory #{@appdir} exit?"
    end
  end

  def acquire_token
    token_file ="#{home_directory}/.appdrop"
    if File.exists?(token_file)
      @token = IO.readlines(token_file)
    else
      p "You need an authorization token which you can get at http://appdrop.com/apps/#{@appid}/manage"
      p "Please paste the token here:"
      @token = g
      File.open(token_file,'w') do |f|
        f.write @token
      end      
    end
  end
  
  private
  # for mocking
  def p string
    Kernel.puts string
  end

  def g
    Kernel.gets.chomp
  end
  
  def validate_appdir
    yamls = ["#{@appdir}/app.yaml", "#{@appdir}/app.yml"]
    appid = nil
    unless yamls.any? do |file|
      if File.exists?(file)
        parse = File.open(file) { |yf| YAML::load( yf ) }        
        appid = parse['application'] if parse['application']
      end
    end
      raise FileError, "Directory #{@appdir} does not contain a valid app.yaml or app.yml"
    end
    return appid
  end
  
  def home_directory
    ENV["HOME"] ||
      (ENV["HOMEPATH"] && "#{ENV["HOMEDRIVE"]}#{ENV["HOMEPATH"]}") ||
      "/"
  end
end
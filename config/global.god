begin
  require File.join(File.dirname(__FILE__),'email.god') 
  God.contact(:email) do |c|
    c.name = 'jchris'
    c.email = 'jchris@grabb.it'
  end
rescue
end

# todo add mongrel monitoring
God::EventHandler.load

base_path = ENV['DNS_SERVER_ROOT'] || File.expand_path("../../../", __FILE__)
ENV['DNS_SERVER_ROOT'] = base_path

God::Contacts::Email.defaults do |d|
  d.from_email = 'god@icehook.com'
  d.from_name = 'God'
  d.delivery_method = :sendmail
end

God.contact(:email) do |c|
  c.name = 'keith'
  c.group = 'developers'
  c.to_email = 'klarrimore@icehook.com'
end

God.contact(:email) do |c|
  c.name = 'randy'
  c.group = 'operations'
  c.to_email = 'rweinberger@icehook.com'
end

God.load File.join(File.dirname(__FILE__), "dnsserver.god")

#!/usr/bin/env ruby

# https://github.com/lostisland/faraday/blob/master/script/proxy-server

require 'webrick'
require 'webrick/httpproxy'

username = 'admin'
password = '123456'

match_credentials = lambda { |credentials|
  got_username, got_password = credentials.to_s.unpack('m*')[0].split(':', 2)
  got_username == username && got_password == password
}

auth = proc do |req, res|
  type, credentials = req.header['proxy-authorization'].first.to_s.split(/\s+/, 2)
  unless type == 'Basic' && match_credentials.call(credentials)
    res['proxy-authenticate'] = %(Basic realm="testing")
    raise WEBrick::HTTPStatus::ProxyAuthenticationRequired
  end
end

log_io = $stdout
log_io.sync = true

proxy = WEBrick::HTTPProxyServer.new Port: 8118,
                    ProxyVia: true,
                    Logger: WEBrick::Log.new(log_io),
                    AccessLog: [[log_io, '[%{User-Agent}i] %m  %U  ->  %s %b']],
                    ProxyAuthProc: auth

trap 'INT'  do proxy.shutdown end
trap 'TERM' do proxy.shutdown end

proxy.start

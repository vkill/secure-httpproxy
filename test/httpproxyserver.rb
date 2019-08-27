require 'webrick'
require 'webrick/httpproxy'

log_io = $stdout
log_io.sync = true

proxy = WEBrick::HTTPProxyServer.new Port: 8118,
                    ProxyVia: true,
                    Logger: WEBrick::Log.new(log_io),
                    AccessLog: [[log_io, '[%{User-Agent}i] %m  %U  ->  %s %b']]

trap 'INT'  do proxy.shutdown end
trap 'TERM' do proxy.shutdown end

proxy.start

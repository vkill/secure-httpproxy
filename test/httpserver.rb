require 'webrick'

log_io = $stdout
log_io.sync = true

server = WEBrick::HTTPServer.new Port: 80,
                    Logger: WEBrick::Log.new(log_io),
                    AccessLog: [[log_io, '[%{User-Agent}i] %m  %U  ->  %s %b']]

server.mount_proc '/' do |req, res|
  res.body = "#{req.request_uri.path}"
end

trap 'INT'  do server.shutdown end
trap 'TERM' do server.shutdown end

server.start

require 'test/unit'
require 'pathname'
require 'fileutils'
require 'open3'
require 'timeout'

class IntegrationTest < Test::Unit::TestCase
  @@root = Pathname.new(File.expand_path('../..', __FILE__))

  class << self
    def execute(cmd)
      stdout_str, stderr_str, status = Open3.capture3(cmd)

      puts %Q`
================================================================================
cmd: #{cmd}
status: #{status}
stdout_str:
--------------------
#{stdout_str}
----------
stderr_str:
--------------------
#{stderr_str}
----------
========================================
`

      return [stdout_str, stderr_str, status]
    end

    def startup
      cmd_up = "docker-compose -f #{@@root.join('docker-compose.yml')} -f #{@@root.join('docker-compose.test.yml')} -p secure-httpproxy-test up -d"
      @@cmd_down = "docker-compose -f #{@@root.join('docker-compose.yml')} -f #{@@root.join('docker-compose.test.yml')} -p secure-httpproxy-test down"

      FileUtils.rm_rf Dir.glob(@@root.join('test/nginx_log_njs/*.log').to_s)

      stdout_str, stderr_str, status = execute(cmd_up)
      unless status.success?
        stdout_str, stderr_str, status = execute(@@cmd_down)
        if status.success?
          raise "failed to up services"
        else
          raise "failed to up services and down services"
        end
      end

      sleep 1
    end

    def shutdown
      stdout_str, stderr_str, status = execute(@@cmd_down)
      unless status.success?
        raise 'failed to down services'
      end
    end
  end

  def test_httpproxy_via_njs
    cmd_curl = "curl -x https://proxy.lvh.me:19118 --proxy-cacert #{@@root.join('mkcert/rootCA.pem')} http://172.17.0.1:18080 -v"
    stdout_str, stderr_str, status = self.class.execute(cmd_curl)

    assert(status.success?)
    assert(stdout_str == '/')
    assert(stderr_str.include?("\r\n< Via: 1.1 httpproxyserver1:8118\r\n"))
  end

  def test_httpproxy_with_auth_via_njs
    cmd_curl = "curl -x https://admin:123456@proxy.lvh.me:19119 --proxy-cacert #{@@root.join('mkcert/rootCA.pem')} http://172.17.0.1:18080 -v"
    stdout_str, stderr_str, status = self.class.execute(cmd_curl)

    assert(status.success?)
    assert(stdout_str == '/')
    assert(stderr_str.include?("\r\n< Via: 1.1 httpproxyserver2:8118\r\n"))
  end

  def test_non_httpproxy_via_njs
    cmd_curl = "curl -x https://proxy.lvh.me:19120 --proxy-cacert #{@@root.join('mkcert/rootCA.pem')} http://172.17.0.1:18080 -v"
    stdout_str, stderr_str, status = self.class.execute(cmd_curl)

    assert(status.exitstatus == 35)
    assert(stdout_str == '')
    assert(stderr_str.include?("OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to proxy.lvh.me:19120"))

    assert(open(@@root.join('test/nginx_log_njs/access_stream.log').to_s).read.include?(' TCP 403 '))
  end
end

#! /usr/bin/env ruby
#  encoding: UTF-8
#
#   metrics-jmx-jolokia-heap-mem
#
# DESCRIPTION:
#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#  ./metrics-jmx-jolokia-heap-mem.rb -u http://localhost:8080
#
# LICENSE:
#   Steven Ayers <sayers@equalexperts.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'json'
require 'ostruct'
require 'net/http'
require 'sensu-plugin/metric/cli'
require 'socket'

class MemoryGraphite < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme',
         long: '--scheme SCHEME',
         default: Socket.gethostname.to_s
  option :url, :short => '-u URL', :default => 'http://127.0.0.1:8080', :description => 'The base URL to connect to'

  def run
    if config[:url]
      uri = URI.parse(config[:url])
      config[:host] = uri.host
      config[:port] = uri.port
    else
      unknown "Please provide a URL."
    end
    mem = metrics_hash
    mem.each do |k, v|
      output "#{config[:scheme]}.#{config[:port]}.HeapMemoryUsage.#{k}", v
    end
    ok
  end

  def metrics_hash
    data = meminfo_output
    data.value.pcnt_used = 100.0 * data.value.used / data.value.max
    metrics = {
      max: data.value.max,
      init: data.value.init,
      committed: data.value.committed,
      used: data.value.used,
      pcnt_used: data.value.pcnt_used
    }
  end

  def meminfo_output
    http = Net::HTTP.new(config[:host], config[:port])
    req = Net::HTTP::Get.new('/jolokia/read/java.lang:type=Memory/HeapMemoryUsage')
    res = http.request(req)
    case res.code
      when /^2/
        if json_valid?(res.body)
          json = JSON.parse(res.body, object_class: OpenStruct)
          return json
        else
          unknown "Could not validate JSON Response."
        end
      else
        unknown "Could not validate JSON Response."
    end
  end

  def json_valid?(str)
    JSON.parse(str)
    return true
  rescue JSON::ParserError
    return false
  end
end

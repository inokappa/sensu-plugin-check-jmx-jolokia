#! /usr/bin/env ruby
#  encoding: UTF-8
#
#   metrics-memory-percent
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
#  ./metrics-memory-percent.rb
#
# LICENSE:
#   Copyright 2012 Sonian, Inc <chefs@sonian.net>
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
         description: 'Metric naming scheme, text to prepend to .$parent.$child',
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
    heap_mem = metrics_hash('/jolokia/read/java.lang:type=Memory/HeapMemoryUsage')
    heap_mem.each do |k, v|
      output "#{config[:scheme]}.#{config[:port]}.HeapMemoryUsage.#{k}", v
    end
    non_heap_mem = metrics_hash('/jolokia/read/java.lang:type=Memory/NonHeapMemoryUsage')
    non_heap_mem.each do |k, v|
      output "#{config[:scheme]}.#{config[:port]}.NonHeapMemoryUsage.#{k}", v
    end
    ok
  end

  def metrics_hash(url)
    data = meminfo_output(url)
    if url.include? '/HeapMemoryUsage'
      data.value.pcnt_used = 100.0 * data.value.used / data.value.max
    else
      data.value.pcnt_used = 0
    end
    metrics = {
      max: data.value.max,
      init: data.value.init,
      committed: data.value.committed,
      used: data.value.used,
      pcnt_used: data.value.pcnt_used
    }
  end

  def meminfo_output(url)
    http = Net::HTTP.new(config[:host], config[:port])
    req = Net::HTTP::Get.new(url)
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

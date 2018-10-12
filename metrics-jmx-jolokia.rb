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
  option :path, :short => '-p PATH', :default => '*', :description => 'The path to the desired JMX object (the bit that goes after /jolokia/read/java.lang:type=).'
  option :type, :short => '-t TYPE', :default => 'java.lang', :description => 'The type of request. Defaults to java.lang.type.'

  def run
    if config[:url]
      uri = URI.parse(config[:url])
      config[:host] = uri.host
      config[:port] = uri.port
    else
      unknown "Please provide a URL."
    end
    if config[:path]
      path = '/jolokia/read/' + config[:type] + ':type=' + config[:path]
    end
    metrics = info_output(path).value
    prefix = "#{config[:scheme]}.#{config[:port]}.jvm_metrics"
    output_open_struct(metrics, prefix)

    ok
  end

  def output_open_struct(object, prefix)
    if object.is_a? OpenStruct
      hash = object.to_h
      hash.each do |k, v|
        output_prefix = "#{prefix}.#{k.to_s.gsub('java.lang:type=', '')}"
        output_open_struct(v, output_prefix)
      end
    else
      output prefix, object
    end
  end

  def info_output(url)
    http = Net::HTTP.new(config[:host], config[:port])
    req = Net::HTTP::Get.new(url)
    res = http.request(req)
    case res.code
      when /^2/
        if json_valid?(res.body)
          json = ::JSON.parse(res.body, object_class: OpenStruct)
          return json
        else
          unknown "Could not validate JSON Response."
        end
      else
        unknown "Could not validate JSON Response."
    end
  end

  def json_valid?(str)
    ::JSON.parse(str)
    return true
  rescue ::JSON::ParserError => e
    return false
  end
end

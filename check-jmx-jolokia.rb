#!/usr/bin/env ruby
#
#   sensu-checks-jmx-jolokia
#
# DESCRIPTION:
#   Allows monitoring of JMX beans which have been exposed via Jolokia
#
# OUTPUT:
#   plain text, integer
#
# PLATFORMS:
#   Linux, Windows, macOS
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   ./check-jmx-jolokia.rb -u http://127.0.0.1:8778 -m "java.lang:type=Memory" -a "HeapMemoryUsage" -i used -k value -w 10 -c -100
#
# NOTES:
#   This can ONLY be used in situations where Jolokia is running on the target machine and exposing the JMX beans
#
# LICENSE:
#   Lewis England <lewis2004@outlook.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'json'
require 'net/http'

class String
  def is_integer?
    self.to_i.to_s == self
  end
end

class CheckJmxJolokia < Sensu::Plugin::Check::CLI

  option :url, :short => '-u URL', :default => 'http://127.0.0.1:8778', :description => 'The base URL to connect to (including port)'
  option :host, :short => '-h HOST', :default => 'localhost', :description => '(Optional) The name of the host to connect to'
  option :path, :short => '-p PATH', :default => '/jolokia/read', :description => 'The URL path to the base of Jolokia'
  option :timeout, :short => '-t SECS', :proc => proc { |a| a.to_i }, :default => 15, :description => 'URL request timeout, in seconds'
  option :mbean, :short => '-m Mbean', :long => '--mbean Mbean', :description => 'Name of the MBean to query'
  option :attribute, :short => '-a Attribute', :long => '--attribute VALUE', :description => 'Name of the MBean attribute to query'
  option :innner_path, :short => '-i Inner PATH', :long => '--innner-path Inner PATH', :description => '(Optional) The inner path of the MBean attribute'
  option :json_key, :short => '-k KEY', :long => '--key KEY', :description => 'Name of the MBean attribute\'s key to query'
  option :crit, :short => '-c VALUE', :long => '--critical VALUE', :description => 'The CRITICAL state. Can be a string to match to or a integer threshold'
  option :warn, :short => '-w VALUE', :long => '--warning VALUE', :description => 'The WARNING state. Can be a string to match to or a integer threshold'

  def run
    if config[:url]
      uri = URI.parse(config[:url])
      config[:host] = uri.host
      config[:port] = uri.port
    else
      unless config[:host] && config[:path]
        unknown 'No URL specified'
      end
    end

    begin
      Timeout.timeout(config[:timeout]) do
        get_resource
      end
    rescue Timeout::Error
      critical "Connection timed out"
    rescue => e
      critical "Connection error: #{e.message}"
    end
  end

  def json_valid?(str)
    JSON.parse(str)
    return true
  rescue JSON::ParserError
    return false
  end

  def get_resource
    http = Net::HTTP.new(config[:host], config[:port])
    unless config[:innner_path]
      req = Net::HTTP::Get.new([config[:path], config[:mbean], config[:attribute]].compact.join('/'))
      msg = "#{config[:attribute]} #{config[:json_key]} =>"
    else
      req = Net::HTTP::Get.new([config[:path], config[:mbean], config[:attribute], config[:innner_path]].compact.join('/'))
      msg = "#{config[:attribute]} #{config[:innner_path]} #{config[:json_key]} =>"
    end
    res = http.request(req)

    case res.code
    when /^2/
      if json_valid?(res.body)
        json = JSON.parse(res.body)
        if config[:warn].is_integer?
          warning "#{msg} #{json[config[:json_key]].to_i}" if json[config[:json_key]].to_i > config[:warn].to_i
        else
          warning "#{msg} #{json[config[:json_key]]}" if json[config[:json_key]] == config[:warn]
        end
        if config[:crit].is_integer?
          critical "#{msg} #{json[config[:json_key]].to_i}" if json[config[:json_key]].to_i > config[:crit].to_i
        else
          critical "#{msg} #{json[config[:json_key]]}" if json[config[:json_key]] == config[:crit]
        end
        ok "#{msg} #{json[config[:json_key]]}"
      else
        critical "Response contains invalid JSON."
      end
    else
      critical "Jolokia endpoint inaccessible."
    end
  end
end
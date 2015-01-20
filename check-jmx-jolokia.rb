#!/usr/bin/env ruby
#
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'json'
require 'net/http'

class CheckJmxJolokia < Sensu::Plugin::Check::CLI

  option :url, :short => '-u URL'
  option :host, :short => '-h HOST'
  option :path, :short => '-p PATH', :default => '/jolokia/read'
  option :timeout, :short => '-t SECS', :proc => proc { |a| a.to_i }, :default => 15
  option :mbean, :short => '-m Mbeans', :long => '--mbean VALUE'
  option :attribute, :short => '-a Attribute', :long => '--attribute VALUE'
  option :innner_path, :short => '-i Inner PATH', :long => '--innner-path Inner PATH'
  option :json_key, :short => '-k KEY', :long => '--key KEY'
  option :crit, :short => '-c VALUE', :long => '--critical VALUE'
  option :warn, :short => '-w VALUE', :long => '--warning VALUE'

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
      timeout(config[:timeout]) do
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
        critical "#{msg} #{json[config[:json_key]].to_i}" if json[config[:json_key]].to_i > config[:crit].to_i
        warning "#{msg} #{json[config[:json_key]].to_i}" if json[config[:json_key]].to_i > config[:warn].to_i
        ok "#{msg} #{json[config[:json_key]].to_i}"
      else
        critical "Response contains invalid JSON."
      end
    else
      critical "Jolokia endpoint inaccessible."
    end
  end
end

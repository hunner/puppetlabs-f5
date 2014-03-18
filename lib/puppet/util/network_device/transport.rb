## This code is simply the icontrol gem renamed and mashed up.
require 'openssl'
require 'savon'

module Puppet::Util::NetworkDevice::F5
  class Transport
    attr_reader :hostname, :username, :password, :directory
    attr_accessor :wsdls, :endpoint, :interfaces

    def initialize hostname, username, password, wsdls = []
      @hostname = hostname
      @username = username
      @password = password
      @directory = File.dirname(__FILE__) + '/wsdl/'
      @wsdls = wsdls
      @endpoint = '/iControl/iControlPortal.cgi'
      @interfaces = {}
    end

    def get_interfaces
      @wsdls.each do |wsdl|
        wsdl = wsdl.sub(/.wsdl$/, '')
        wsdl_path = @directory + '/' + wsdl + '.wsdl'

        if File.exists? wsdl_path
          url = 'https://' + @hostname + '/' + @endpoint
          file = 'file://' + wsdl_path
          @interfaces[wsdl] = Savon.client(wsdl: file, ssl_verify_mode: :none,
            basic_auth: [@username, @password], endpoint: url, namespace: 'urn:iControl')
        end
      end

      @interfaces
    end

    def get_all_interfaces
      @wsdls = self.available_wsdls
      self.get_interfaces
    end

    def available_interfaces
      @interfaces.keys.sort
    end

    def available_wsdls
      Dir.entries(@directory).delete_if {|file| !file.end_with? '.wsdl'}.map {|file| file.gsub(/\.wsdl$/, '')}.sort
    end
  end
end

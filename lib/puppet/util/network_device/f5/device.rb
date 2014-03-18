require 'uri'
require 'puppet/util/network_device/f5/facts'
require 'puppet/util/network_device/f5/transport'

class Puppet::Util::NetworkDevice::F5::Device

  attr_accessor :url, :transport, :partition

  def initialize(url, option = {})
    @url = URI.parse(url)
    @option = option

    modules = [
      'LocalLB.Class',
      'LocalLB.Monitor',
      'LocalLB.NodeAddress',
      'LocalLB.ProfileClientSSL',
      'LocalLB.ProfilePersistence',
      'LocalLB.Pool',
      'LocalLB.PoolMember',
      'LocalLB.Rule',
      'LocalLB.SNAT',
      'LocalLB.SNATPool',
      'LocalLB.SNATTranslationAddress',
      'LocalLB.VirtualServer',
      'Management.KeyCertificate',
      'Management.Partition',
      'Management.SNMPConfiguration',
      'Management.UserManagement',
      'Networking.RouteTable',
      'System.ConfigSync',
      'System.Inet',
      'System.Session',
      'System.SystemInfo'
    ]

    Puppet.debug("Puppet::Device::F5: connecting to F5 device #{@url.host}.")
    @transport ||= Puppet::Util::NetworkDevice::F5::Transport.new(@url.host, @url.user, @url.password, modules).get_interfaces

    # Access Common partition by default:
    if @url.path == '' or @url.path == '/'
      @partition = 'Common'
    else
      @partition = /\/(.*)/.match(@url.path).captures
    end

    # System.Session API not supported until V11.
    Puppet.debug("Puppet::Device::F5: connecting to partition #{@partition}.")
    require 'pry'
    binding.pry
    if transport['System.Session']
      transport['System.Session'].call(:set_active_folder)[@partition]
      #transport['System.Session'].call(:set_active_folder(@partition))
    else
      transport['Management.Partition'].call(:set_active_partition)[@partition]
      #transport['Management.Partition'].call(:set_active_partition(@partition))
    end
  end

  def facts
    @facts ||= Puppet::Util::NetworkDevice::F5::Facts.new(@transport)
    facts = @facts.retrieve

    # inject F5 partition info.
    facts['partition'] = @partition
    facts
  end
end

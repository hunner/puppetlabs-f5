require 'puppet/provider/f5'
require 'puppet/util/network_device/f5'

Puppet::Type.type(:f5_snmpconfiguration).provide(:f5_snmpconfiguration, :parent => Puppet::Provider::F5) do
  @doc = "Manages f5 snmpconfiguration properties"

  confine :feature => :posix
  defaultfor :feature => :posix

  def self.wsdl
    'Management.SNMPConfiguration'
  end
  def wsdl
    self.class.wsdl
  end

  def self.snmpmethods
    {
      :access_info                => 'access_info', #Array
      :agent_group_id             => 'group_id',
      :agent_interface            => 'agent_intf',
      :agent_listen_address       => 'agent_listen_addresses', #Array
      :agent_trap_state           => 'state',
      :agent_user_id              => 'user_id',
      :auth_trap_state            => 'state',
      :check_disk                 => 'disk_info',
      :check_file                 => 'file_info',
      :check_load                 => 'load_info',
      :check_process              => 'proc_info',
      :client_access              => 'client_access_info',
      :community_to_security_info => 'security_info',
      :create_user                => 'user_info', #array
      :engine_id                  => 'engine_id',
      :exec                       => 'exec_info', #array
      :exec_fix                   => 'exec_info', #array
      :generic_traps_v2           => 'sink_info', #array
      :group_info                 => 'group_info', #array
      :ignore_disk                => 'ignore_disk', #array
      :pass_through               => 'passthru_info', #array
      :pass_through_persist       => 'passthru_info', #array
      :process_fix                => 'fix_info', #array
      :proxy                      => 'proxy_info', #array
      :readonly_community         => 'ro_community_info', #array
      :readonly_user              => 'ro_user_info', #array
      :readwrite_community        => 'rw_community_info', #array
      :readwrite_user             => 'rw_user_info', #array
      :system_information         => 'system_info',
      :trap_community             => 'community',
      :view_info                  => 'view_info', #array
    }
  end

  def self.instances
    [new(:name => 'agent')]
  end

  def access_info
    transport[wsdl].get(:get_access_info)
  end

  def agent_group_id
    transport[wsdl].get(:get_agent_group_id)
  end

  def agent_interface
    transport[wsdl].get(:get_agent_interface)
  end

  def agent_listen_address
    require 'pry'
    binding.pry
    response = transport[wsdl].get(:get_agent_listen_address)
    response.each do |hash|
      if hash[:ipport][:address].is_a?(Hash)
        hash[:ipport][:address] == ''
      end
    end
    response
  end

  def agent_trap_state
  end
  def agent_user_id
  end
  def auth_trap_state
  end
  def check_disk
  end
  def check_file
  end
  def check_load
  end
  def check_process
  end
  def client_access
  end
  def community_to_security_info
  end
  def create_user
  end
  def engine_id
  end
  def exec
  end
  def exec_fix
  end
  def generic_traps_v2
  end
  def group_info
  end
  def ignore_disk
  end
  def pass_through
  end
  def pass_through_persist
  end
  def process_fix
  end
  def proxy
  end
  def readonly_community
  end
  def readonly_user
  end
  def readwrite_community
  end
  def readwrite_user
  end
  def system_information
  end
  def trap_community
  end
  def view_info
  end

  snmphash=Puppet::Util::NetworkDevice::F5.snmpconfiguration_methods
  snmpmethods.keys.each do |method, message_name|
    #define_method(method.to_sym) do
    #  response = transport[wsdl].call("get_#{method}".to_sym).body["get_#{method}_response".to_sym][:return]
    #  if response.is_a?(String)
    #    response
    #  else
    #    response[:item]
    #  end
    #end

    define_method("#{method}=") do |value|
      if snmphash[method].class == Array
        add=(value-@methods_data[method])
        rem=(@methods_data[method]-value)
        if rem.empty? == false && transport[wsdl].operations.include?("remove_#{method}".to_sym)
          transport[wsdl].call("remove_#{method}".to_sym, rem)
        end
      else
        add=value
      end
      if add.empty? == false && transport[wsdl].operations.include?("set_#{method}".to_sym)
        transport[wsdl].call("set_#{method}".to_sym, add)
      end
    end
  end

  ### Inconsistent method handling in the BigIP. All methods managing arrays
  ### append to the existing elements but set_agent_listen_address and
  ### set_client_access replace them. Case C1042181 opened with F5.

  ['agent_listen_address','client_access'].each do |method|
    define_method("#{method}=") do |value|
      if transport[wsdl].operations.include?("set_#{method}".to_sym)
        transport[wsdl].call("set_#{method}".to_sym, value)
      end
    end
  end

end

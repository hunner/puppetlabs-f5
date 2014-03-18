require 'puppet/util/network_device/f5'

class Puppet::Util::NetworkDevice::F5::Facts

  attr_reader :transport

  F5_WSDL = 'System.SystemInfo'

  def initialize(transport)
    @transport = transport
  end

  def to_64i(value)
    (value.high.to_i << 32) + value.low.to_i
  end

  def retrieve
    @facts = {}
    [ 'base_mac_address',
      'group_id',
      'hardware_information',
      'marketing_name',
      'pva_version',
      'system_id',
      'uptime',
      'version'
    ].each do |key|
        @facts[key] = @transport[F5_WSDL].send("get_#{key}".to_s)
    end

    # TODO:  Make this an array of items to get, so we can determine the _response
    # to use.
    system_info = @transport[F5_WSDL].call(:get_system_information).to_hash
    system_info[:get_system_information_response][:return].each do |key|
      @facts[key] = system_info[:get_system_information_response][:return][key]
    end

    # We only want entries from the first item.
    hardware_info = @transport[F5_WSDL].call(:get_hardware_information).to_hash
    hardware_info[:get_hardware_information_response][:return].each do |key|
      @facts["hardware_#{key}"] = hardware_info[:get_hardware_information_response][:return].first[key]
      fact_key = key == 'name' ? "hardware_#{hardware.name}" : "hardware_#{hardware.name}_#{key}"
      @facts[fact_key] = hardware[:get_hardware_information_response][:return][key]
    end

    disk_info = @transport[F5_WSDL].call(:get_disk_usage_information).to_hash
    disk_info[:get_disk_usage_information_response][:return][:usages][:item].each do |disk|
      @facts["disk_size_#{disk[:partition_name].gsub('/','')}"]  = "#{(to_64i(disk[:total_blocks]) * to_64i(disk[:block_size]))/1024/1024} MB"
      @facts["disk_free_#{disk[:partition_name].gsub('/', '')}"] = "#{(to_64i(disk[:free_blocks]) * to_64i(disk[:block_size]))/1024/1024} MB"
    end

    # cleanup of f5 output to match existing facter key values.
    map = { 'host_name'        => 'fqdn',
            'base_mac_address' => 'macaddress',
            'os_machine'       => 'hardwaremodel',
            'uptime'           => 'uptime_seconds',
    }
    @facts = Hash[@facts.map {|k, v| [map[k] || k, v] }]\

    if @facts['fqdn'] then
      fqdn = @facts['fqdn'].split('.', 2)
      @facts['hostname'] = fqdn.shift
      @facts['domain']   = fqdn
    end

    if @facts['uptime_seconds'] then
      @facts['uptime']       = "#{String(@facts['uptime_seconds']/86400)} days" # String
      @facts['uptime_hours'] = @facts['uptime_seconds'] / (60 * 60)             # Integer
      @facts['uptime_days']  = @facts['uptime_hours'] / 24                      # Integer
    end

    if @facts['hardware_cpus_versions']
      @facts['hardware_cpus_versions'].each { |key| @facts["hardware_#{key.name.downcase.gsub(/\s/,'_')}"] = key.value }
      @facts.delete('hardware_cpus_versions')
      @facts.delete('hardware_information')
      @facts.delete('versions')
    end

    @facts['timezone'] = @transport[F5_WSDL].call(:get_time_zone)[:get_time_zone_response][:return][:time_zone]
    @facts
  end
end

require 'puppet/provider/f5'

Puppet::Type.type(:f5_rule).provide(:f5_rule, :parent => Puppet::Provider::F5) do
  @doc = "Manages f5 pool"

  confine :feature => :posix
  defaultfor :feature => :posix

  def self.wsdl
    'LocalLB.Rule'
  end

  def wsdl
    self.class.wsdl
  end

  def self.instances
    transport[wsdl].call(:get_list).body[:get_list_response][:return][:item].collect do |name|
      new(:name   => name,
          :ensure => :present
         )
    end
  end

  def definition
    Puppet.debug("Puppet::Provider::F5_Rule: retrieving #{resource[:name]} rule definition")
    output = transport[wsdl].call(:query_rule, message: { 'rule_names' => resource[:name] })
    output.body[:query_rule_response][:return]
  end

  def definition=(val)
    Puppet.debug("Puppet::Provider::F5_Rule: updating #{resource[:name]} rule definition")
    rule = {"rule_name" => resource[:name], "rule_definition" => resource[:definition]}
    transport[wsdl].call(:modify_rule, message: rule)
  end

  def create
    Puppet.debug("Puppet::Provider::F5_Rule: creating #{resource[:name]}")
    rule = {"rule_name" => resource[:name], "rule_definition" => resource[:definition]}
    transport[wsdl].call(:create, message: rule)
  end

  def destroy
    Puppet.debug("Puppet::Provider::F5_Rule: destroying #{resource[:name]}")
    transport[wsdl].call(:delete_rule, message: resource[:name])
  end

  def exists?
    transport[wsdl].call(:get_list).body.include?(resource[:name])
  end
end

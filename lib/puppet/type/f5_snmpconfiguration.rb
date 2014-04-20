Puppet::Type.newtype(:f5_snmpconfiguration) do
  @doc = "Manage F5 SNMP configuration properties."

  apply_to_device
  fail("f5_snmpconfiguration is currently unsupported in the module.")

  newparam(:name, :namevar=>true) do
    desc "The SNMP type name. Fixed to 'agent'."
    newvalues(/^(agent)+$/)
    newvalues(/^[[:alpha:][:digit:]\.\-]+$/)
  end

  newproperty(:access_info) do
  end

  newproperty(:agent_group_id) do
  end

  newproperty(:agent_interface) do
  end

  newproperty(:agent_listen_address) do
  end

  newproperty(:agent_trap_state) do
  end

  newproperty(:agent_user_id) do
  end

  newproperty(:auth_trap_state) do
  end

  newproperty(:check_disk) do
  end

  newproperty(:check_file) do
  end

  newproperty(:check_load) do
  end

  newproperty(:check_process) do
  end

  newproperty(:client_access) do
  end

  newproperty(:community_to_security_info) do
  end

  newproperty(:create_user) do
  end

  newproperty(:engine_id) do
  end

  newproperty(:exec) do
  end

  newproperty(:exec_fix) do
  end

  newproperty(:generic_traps_v2) do
  end

  newproperty(:group_info) do
  end

  newproperty(:ignore_disk) do
  end

  newproperty(:pass_through) do
  end

  newproperty(:pass_through_persist) do
  end

  newproperty(:process_fix) do
  end

  newproperty(:proxy) do
  end

  newproperty(:readonly_community) do
  end

  newproperty(:readonly_user) do
  end

  newproperty(:readwrite_community) do
  end

  newproperty(:readwrite_user) do
  end

  newproperty(:system_information) do
  end

  newproperty(:trap_community) do
  end

  newproperty(:view_info) do
  end

end

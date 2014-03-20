require 'puppet/provider/f5'

Puppet::Type.type(:f5_user).provide(:f5_user, :parent => Puppet::Provider::F5) do
  @doc = "Manages F5 user"

  confine    :feature => :posix
  defaultfor :feature => :posix

  def self.wsdl
    'Management.UserManagement'
  end

  def wsdl
    self.class.wsdl
  end

  def self.instances
    Puppet.debug("Puppet::Provider::F5_User: instances")
    transport[wsdl].call(:get_list).body[:get_list_response][:return][:item].collect do |item|
      new(:name   => item[:name],
          :ensure => :present
         )
    end
  end

  def create
    Puppet.debug("Puppet::Provider::F5_User: creating F5 user #{resource[:name]}")
    user_info = {
      :user           => { :name => resource[:name], :full_name => resource[:fullname]},
      :password       => { :password => resource[:password]['password'], :is_encrypted => resource[:password]['is_encrypted'] },
      :login_shell    => resource[:login_shell],
      :permissions    => [resource[:user_permission]],
    }

    # Create_user() and create_user_2() are deprecated and create_user_3()
    # attempts to autodiscover the other values like user_id.
    transport[wsdl].call(:create_user_3, message: user_info)
  end

  def destroy
    Puppet.debug("Puppet::Provider::F5_User: destroying F5 user #{resource[:name]}")

    transport[wsdl].call(:delete_user, message: resource[:name])
  end

  def exists?
    transport[wsdl].call(:get_list).body[:get_list_response][:return][:item].each do |user|
      return true if user[:name[resource[:name]]]
    end
  end

  def query_user_property(user, property)
    message = { user_names: { item: Array(user) } }
    result = transport[wsdl].call("get_#{property}".to_sym, message: message).body
    result["get_#{property}_response".to_sym][:return][:item]
  end

  def user_permission
    result = {}
    message = { user_names: { item: Array(resource[:name])}}
    user_permission = transport[wsdl].call(:get_user_permission,
      message: message).body[:get_user_permission_response][:return][:item][:item]

    if user_permission
      result[user_permission[:partition]] = user_permission[:role]
    end

    result
  end

  def user_permission=(value)
    permission = []
    resource[:user_permission].keys.each do |part|
      permission.push({:role =>  resource[:user_permission][part], :partition => part})
    end
    #value = transport[wsdl].send("set_user_permission", [resource[:name]], [permission]) unless permission.empty?
    message = { user_names: resource[:name], permissions: [permisson] }
    transport[wsdl].call(:set_user_permission, message) unless permission.empty?
  end

  def password
    Puppet.debug("Puppet::Provider::F5_User: retrieving encrypted_password for #{resource[:name]}")

    encrypted_password = transport[wsdl].call(:get_encrypted_password,
      message: { user_names: { :item => [resource[:name]] } }).body[:get_encrypted_password_response][:return][:item]

    { 'password' => encrypted_password, 'is_encrypted' => true }
  end

  def notsure
    # Passing from a password (encrypted) to the same password (unencrypted)
    # won't trigger changes as passwords are always stored in an encrypted form
    # on the bigip. The only consequence is that the crypt salt will remain the
    # same.
    if resource[:password]['is_encrypted'] != true
      salt = old_encrypted_password.sub(/^(\$1\$\w+?\$).*$/, '\1')
      new_encrypted_password = resource[:password]['password'].crypt(salt)
    else
      new_encrypted_password = resource[:password]['password']
    end

    if new_encrypted_password == old_encrypted_password
      result['password']     = resource[:password]['password']
      result['is_encrypted'] = resource[:password]['is_encrypted']
    end

    result
  end

  def password=(value)
    Puppet.debug("Puppet::Provider::F5_User: setting password for #{resource[:name]}")
    transport[wsdl].change_password_2([resource[:name]],[{ :password => resource[:password]['password'], :is_encrypted => resource[:password]['is_encrypted'] }])
  end


  def fullname
    query_user_property(resource[:name], 'fullname')
  end

  def fullname=(value)
    message = { user_names: resource[:name], fullnames: value }
    transport[wsdl].call(:set_fullname, message: message).body[:set_fullname_response][:return]
  end

  def login_shell
    query_user_property(resource[:name], 'login_shell')
  end

  def login_shell=(value)
    message = { user_names: resource[:name], shells: value }
    transport[wsdl].call(:set_login_shell, message: message).body[:set_fullname_response][:return]
  end

end

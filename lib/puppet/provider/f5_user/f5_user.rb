require 'puppet/provider/f5'

Puppet::Type.type(:f5_user).provide(:f5_user_09, :parent => Puppet::Provider::F5) do
  @doc = "Manages F5 user"

  confine    :feature => :posix
  defaultfor :feature => :posix

  def self.wsdl
    'Management.UserManagement'
  end

  def wsdl
    self.class.wsdl
  end

  def user_permission
  end

  def self.instances
    Puppet.debug("Puppet::Provider::F5_User: instances")
    transport[wsdl].call(:get_list).body[:get_list_response][:return][:item].collect do |item|
      new(:name   => item[:name],
          :ensure => :present
         )
    end
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

  methods = [
    'home_directory',
    'role'
  ]

  methods.each do |method|
    define_method(method.to_sym) do
      if transport[wsdl].respond_to?("get_#{method}".to_sym)
        Puppet.debug("Puppet::Provider::F5_User: retrieving #{method} for #{resource[:name]}")
        transport[wsdl].send("get_#{method}", resource[:name]).first.to_s
      end
    end
  end

  methods.each do |method|
    define_method("#{method}=") do |value|
      if transport[wsdl].respond_to?("set_#{method}".to_sym)
        transport[wsdl].send("set_#{method}", resource[:name], resource[method.to_sym])
      end
    end
  end

  def create
    Puppet.debug("Puppet::Provider::F5_User: creating F5 user #{resource[:name]}")
    user_info_2 = {
      :user           => { :name => resource[:name], :full_name => resource[:fullname]},
      :password       => { :password => resource[:password]['password'], :is_encrypted => resource[:password]['is_encrypted'] },
      :home_directory => resource[:home_directory],
      :login_shell    => resource[:login_shell],
      :user_id        => resource[:user_id],
      :group_id       => resource[:group_id],
      :role           => resource[:role],
    }
    transport[wsdl].create_user_2([user_info_2])
  end

  def destroy
    Puppet.debug("Puppet::Provider::F5_User: destroying F5 user #{resource[:name]}")
    transport[wsdl].delete_user(resource[:name])
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

  def fullname
    transport[wsdl].call(:get_fullname, message: { user_names: resource[:name] }).body[:get_fullname_response][:return]
    query_user_property(resource[:name], 'fullname')
  end

  def fullname=(value)
    message = { user_names: resource[:name], fullnames: value }
    transport[wsdl].call(:set_fullname, message: message).body[:get_fullname_response][:return]
  end

  def login_shell
    #transport[wsdl].call(:get_login_shell, message: { user_names: resource[:name] }).body[:get_login_shell][:return]
    query_user_property(resource[:name], 'login_shell')
  end

  def fullname=(value)
    message = { user_names: resource[:name], shells: value }
    transport[wsdl].call(:set_fullname, message: message).body[:set_fullname_response][:return]
  end

end

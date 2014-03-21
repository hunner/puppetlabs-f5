require 'puppet/provider/f5'

Puppet::Type.type(:f5_certificate).provide(:f5_certificate, :parent => Puppet::Provider::F5 ) do
  @doc = "Manages f5 certificates"

  confine :feature => :posix
  defaultfor :feature => :posix

  mk_resource_methods

  def self.wsdl
    'Management.KeyCertificate'
  end

  def wsdl
    self.class.wsdl
  end

  def self.instances
    f5certs = []

    modes = [ "MANAGEMENT_MODE_DEFAULT",
              "MANAGEMENT_MODE_WEBSERVER",
              "MANAGEMENT_MODE_EM",
              "MANAGEMENT_MODE_IQUERY",
              "MANAGEMENT_MODE_IQUERY_BIG3D" ]

    modes.each do |mode|
      begin
        transport[wsdl].call(:get_certificate_list, message: {mode: mode}).body[:get_certificate_list_response][:return][:item].each do |cert|
          # F5 certificate bundles have a single cert id so we can't manage
          # them individually, only as a single bundle.
          cert = {
            :name   => cert[:certificate][:cert_info][:id],
            :ensure => :present,
            :mode   => mode
          }
          f5certs << new(cert)
        end
      rescue Exception => e
        # We simply treat this as no certificates.
        Puppet.debug("Puppet::Provider::F5_Certificate: ignoring get_certificate_list exception \n #{e.message}")
      end
    end

    f5certs
  end

  # Modify each key to have its instance as the provider
  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    @property_hash.clear
  end

  def content
    # Fetch and calculate all certificate sha1
    message = { mode: @property_hash[:mode], cert_ids: {item: @property_hash[:name]}}
    value = transport[wsdl].call(:certificate_export_to_pem, message: message).body[:certificate_export_to_pem_response][:return][:item]
    certs = value.scan(/([-| ]*BEGIN CERTIFICATE[-| ]*.*?[-| ]*END CERTIFICATE[-| ]*)/m).flatten

    certs_sha1 = certs.collect { |cert|
      Puppet::Util::NetworkDevice::F5.fingerprint(cert)
    }

    "sha1(#{certs_sha1.sort.inspect})"
  end

  def content=(value)
    Puppet.debug("Puppet::Provider::F5_Cert: replacing cetificate #{resource[:name]}")

    # Replace key/cert altogether in one step if they are bundled.
    if resource[:real_content].match(/([-| ]*BEGIN [R|D]SA (?:PRIVATE|PUBLIC) KEY[-| ]*.*?[-| ]*END [R|D]SA (?:PRIVATE|PUBLIC) KEY[-| ]*)/m)
      transport[wsdl].key_delete(resource[:mode], [resource[:name]])
      transport[wsdl].certificate_delete(resource[:mode], [resource[:name]])
      transport[wsdl].key_import_from_pem(resource[:mode], [resource[:name]], [ resource[:real_content] ], true)
      transport[wsdl].certificate_import_from_pem(resource[:mode], [resource[:name]], [ resource[:real_content] ], true)
    else
      transport[wsdl].certificate_import_from_pem(resource[:mode], [resource[:name]], [ resource[:real_content] ], true)
    end
  end

  def create
    @property_hash[:ensure] = :present
    self.class.resource_type.validproperties.each do |property|
      if val = resource.should(property)
        @property_hash[property] = val
      end
    end
    transport[wsdl].certificate_import_from_pem(resource[:mode], [resource[:name]], [ resource[:real_content] ], true)
  end

  def destroy
    @property_hash[:ensure] = :absent
    transport[wsdl].certificate_delete(resource[:mode], [ resource[:name] ])
  end

  def exists?
    Puppet.debug("Puppet::Provider::F5_certificate::Ensure for #{@property_hash[:name]}: #{@property_hash[:ensure]}")
    @property_hash[:ensure] == :present
  end
end

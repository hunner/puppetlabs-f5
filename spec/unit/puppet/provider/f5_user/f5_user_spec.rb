require 'spec_helper'
require "savon/mock/spec_helper"

describe Puppet::Type.type(:f5_user).provider(:f5_user) do
  include Savon::SpecHelper

  before(:each) {
    # Turn on mocking for savon
    savon.mock!

    # Fake url to initialize the device against
    allow(Facter).to receive(:value).with(:url).and_return("https://admin:admin@f5.puppetlabs.lan/")

    # All creations of provider instances seem to call this
    message = { folder: "/Common" }
    #this xml file is for set_active_partition, not set_active_folder, but meh
    fixture = File.read("spec/fixtures/f5/management_partition/set_active_partition.xml")
    savon.expects(:set_active_folder).with(message: message).returns(fixture)

    # Not needed any more
    #allow(Puppet::Util::NetworkDevice).to receive(:current).and_return device
    #allow(device).to receive(:transport).and_return transport
    #allow(transport).to receive(:get_interfaces)
  }

  # Not needed any more
  #let(:device) { double(Puppet::Util::NetworkDevice) }
  #let(:transport) { double(Puppet::Util::NetworkDevice::F5::Transport) }

  after(:each)  { savon.unmock! }

  let(:f5_user) do
    Puppet::Type.type(:f5).new(
      :name            => 'test',
      :password        => { 'is_encrypted' => false, 'password' => 'beep' },
      :login_shell     => '/bin/bash',
      :user_permission => { '[All]' => 'USER_ROLE_ADMINISTRATOR' },
      :description     => 'beep',
      :fullname        => 'awyeah',
    )
  end

  let(:provider) { f5_user.provider }

  describe '#instances' do
    it do
      # Update this xml file with a real xml response
      get_list_xml = File.read("spec/fixtures/f5/management_partition/get_list.xml")
      savon.expects(:get_list).returns(get_list_xml)
      subject.class.instances
    end
  end

end

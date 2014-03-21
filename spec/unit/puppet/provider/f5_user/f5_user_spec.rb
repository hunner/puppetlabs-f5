require 'spec_helper'
require "savon/mock/spec_helper"

describe Puppet::Type.type(:f5_user).provider(:f5_user) do
  include Savon::SpecHelper

  before(:each) { savon.mock!   }
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
      savon.expects(:get_list)
      subject.class.instances
    end
  end

end

# Encoding: utf-8
require_relative 'spec_helper'

describe 'openvswitch::build_openvswitch_source' do
  before do
    neutron_stubs
    @chef_run = ::ChefSpec::Runner.new(::UBUNTU_OPTS) do |n|
      n.set['openstack']['compute']['network']['service_type'] = 'neutron'
    end
    @chef_run.converge 'openstack-network::openvswitch'
    @chef_run.converge 'openstack-network::build_openvswitch_source'
  end

  it 'does not install openvswitch build dependencies when nova networking' do
    chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS
    node = chef_run.node
    node.set['openstack']['compute']['network']['service_type'] = 'nova'
    chef_run.converge 'openstack-network::openvswitch'
    chef_run.converge 'openstack-network::build_openvswitch_source'
    ['build-essential', 'pkg-config', 'fakeroot', 'libssl-dev', 'openssl', 'debhelper', 'autoconf'].each do |pkg|
      expect(chef_run).to_not install_package pkg
    end
  end

  # since our mocked version of ubuntu is precise, our compile
  # utilities should be installed to build OVS from source
  it 'installs openvswitch build dependencies' do
    ['build-essential', 'pkg-config', 'fakeroot', 'libssl-dev', 'openssl', 'debhelper', 'autoconf'].each do |pkg|
      expect(@chef_run).to install_package pkg
    end
  end

  it 'installs openvswitch switch dpkg' do
    pkg = @chef_run.dpkg_package('openvswitch-switch')

    pkg.source.should eq '/var/chef/cache/22df718eb81fcfe93228e9bba8575e50/openvswitch-switch_1.10.2-1_amd64.deb'
    pkg.action.should eq [:nothing]
  end

  it 'installs openvswitch datapath dkms dpkg' do
    pkg = @chef_run.dpkg_package('openvswitch-datapath-dkms')

    pkg.source.should eq '/var/chef/cache/22df718eb81fcfe93228e9bba8575e50/openvswitch-datapath-dkms_1.10.2-1_all.deb'
    pkg.action.should eq [:nothing]
  end

  it 'installs openvswitch pki dpkg' do
    pkg = @chef_run.dpkg_package('openvswitch-pki')

    pkg.source.should eq '/var/chef/cache/22df718eb81fcfe93228e9bba8575e50/openvswitch-pki_1.10.2-1_all.deb'
    pkg.action.should eq [:nothing]
  end

  it 'installs openvswitch common dpkg' do
    pkg = @chef_run.dpkg_package('openvswitch-common')

    pkg.source.should eq '/var/chef/cache/22df718eb81fcfe93228e9bba8575e50/openvswitch-common_1.10.2-1_amd64.deb'
    pkg.action.should eq [:nothing]
  end
end

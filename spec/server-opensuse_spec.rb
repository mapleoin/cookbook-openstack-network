# Encoding: utf-8
require_relative 'spec_helper'

describe 'openstack-network::server' do
  describe 'opensuse' do
    before do
      neutron_stubs
      @chef_run = ::ChefSpec::Runner.new ::OPENSUSE_OPTS do |n|
        n.set['chef_client']['splay'] = 300
        n.set['openstack']['compute']['network']['service_type'] = 'neutron'
      end
      @node = @chef_run.node
      @chef_run.converge 'openstack-network::server'
    end

    it 'does not install openstack-neutron when nova networking' do
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS
      node = chef_run.node
      node.set['openstack']['compute']['network']['service_type'] = 'nova'
      chef_run.converge 'openstack-network::server'
      expect(chef_run).to_not install_package 'openstack-neutron'
    end

    it 'installs openstack-neutron packages' do
      expect(@chef_run).to install_package 'openstack-neutron'
    end

    it 'enables openstack-neutron service' do
      expect(@chef_run).to enable_service 'openstack-neutron'
    end

    it 'does not install openvswitch package' do
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
        n.set['chef_client']['splay'] = 300
        n.set['openstack']['compute']['network']['service_type'] = 'neutron'
      end
      chef_run.converge 'openstack-network::server'

      expect(chef_run).not_to install_package 'openstack-neutron-openvswitch'
    end

    describe '/etc/sysconfig/neutron' do
      before do
        @file = @chef_run.template('/etc/sysconfig/neutron')
      end

      it 'has proper owner' do
        expect(@file.owner).to eq('root')
        expect(@file.group).to eq('root')
      end

      it 'has proper modes' do
        expect(sprintf('%o', @file.mode)).to eq '644'
      end

      it 'has the correct plugin config location - ovs by default' do
        expect(@chef_run).to render_file(@file.name).with_content(
          '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini')
      end

      it 'uses linuxbridge when configured to use it' do
        chef_run = ::ChefSpec::Runner.new ::OPENSUSE_OPTS do |n|
          n.set['openstack']['network']['interface_driver'] = 'neutron.agent.linux.interface.BridgeInterfaceDriver'
          n.set['openstack']['compute']['network']['service_type'] = 'neutron'
        end
        chef_run.converge 'openstack-network::server'

        expect(chef_run).to render_file('/etc/sysconfig/neutron').with_content(
          '/etc/neutron/plugins/linuxbridge/linuxbridge_conf.ini')
      end
    end
  end
end

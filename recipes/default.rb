#
# Cookbook Name:: git
# Recipe:: default
#
# Copyright 2008-2014, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

case node['platform_family']
when 'debian'
  if node['platform'] == 'ubuntu' && node['platform_version'].to_f < 10.10
    package 'git-core'
  else
    package 'git'
  end
when 'rhel', 'fedora'
  case node['platform_version'].to_i
  when 5
    include_recipe 'yum-epel'
  end
  package 'git'
when 'windows'
  include_recipe 'git::windows'
when 'mac_os_x'
  dmg_package 'GitOSX-Installer' do
    app node['git']['osx_dmg']['app_name']
    package_id node['git']['osx_dmg']['package_id']
    volumes_dir node['git']['osx_dmg']['volumes_dir']
    source node['git']['osx_dmg']['url']
    checksum node['git']['osx_dmg']['checksum']
    type 'pkg'
    action :install
  end
else
  package 'git' do
    package_name case node['platform']
                 when 'omnios'
                   'developer/versioning/git'
                 when 'smartos'
                   'scmgit'
                 end
  end
end

node['git']['config'].each do |level,configurations|
  case level
  when 'project'
    level_switch = ""
  else
    level_switch = "--#{level}"
  end
  configurations.each do |attribute_name,key_value_pair|
    attribute_key = key_value_pair[0]
    attribute_value = key_value_pair[1]
    execute "configure_git_#{level}_#{attribute_name}" do
      command "git config #{level_switch} \"#{attribute_key}\" \"#{attribute_value}\""
      action :run
      not_if "git config --get #{level_switch} \"#{attribute_key}\" | grep -c \"#{attribute_value}\""
    end
  end
end

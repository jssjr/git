provides :git_service

property :service_base_path, String, default: '/srv/git'

include Chef::DSL::IncludeRecipe
include GitCookbook::Helpers

action :create do
  return "#{node['platform']} is not supported by the #{cookbook_name}::#{recipe_name} recipe" if platform_family?('windows', 'mac_os_x', 'freebsd')

  include_recipe 'git'

  directory new_resource.service_base_path do
    owner 'root'
    group 'root'
    mode '0755'
  end

  case node['platform_family']
  when 'debian'
    package 'xinetd'
  when 'rhel', 'fedora'
    package 'git-daemon'
  else
    log 'Platform requires setting up a git daemon service script.'
    log "Hint: /usr/bin/git daemon --export-all --user=nobody --group=daemon --base-path=#{new_resource.service_base_path}"
    return
  end

  template '/etc/xinetd.d/git' do
    backup false
    source 'git-xinetd.d.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      git_daemon_binary: value_for_platform_family(
        'debian' => '/usr/lib/git-core/git-daemon',
        'rhel' => '/usr/libexec/git-core/git-daemon'
      )
    )
  end

  service 'xinetd' do
    action [:enable, :restart]
  end
end

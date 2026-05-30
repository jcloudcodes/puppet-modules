class tom_cat::uninstall (
  Enum['prod', 'dev'] $environment,
  String              $tom_version,
  String              $java_version,
  String              $base_dir,
  String              $install_dir,
  String              $service_name,
  String              $windows_install_dir,
) {

  if $facts['kernel'] == 'Linux' {

    service { $service_name:
      ensure => stopped,
      enable => false,
    }

    file { "/etc/systemd/system/${service_name}.service":
      ensure => absent,
      notify => Exec['systemd_daemon_reload_uninstall'],
    }

    exec { 'systemd_daemon_reload_uninstall':
      command     => '/bin/systemctl daemon-reload',
      path        => ['/usr/bin', '/bin'],
      refreshonly => true,
    }

    file { $install_dir:
      ensure => absent,
      force  => true,
    }

    file { "${base_dir}/apache-tomcat-${tom_version}":
      ensure  => absent,
      recurse => true,
      force   => true,
    }

    file { "/tmp/apache-tomcat-${tom_version}.tar.gz":
      ensure => absent,
    }

  } elsif $facts['kernel'] == 'windows' {

    exec { 'remove_windows_service':
      command   => "powershell.exe -Command \"if (Get-Service -Name '${service_name}' -ErrorAction SilentlyContinue) { Stop-Service -Name '${service_name}' -Force; sc.exe delete ${service_name} }\"",
      provider  => powershell,
      logoutput => true,
    }

    file { $windows_install_dir:
      ensure  => absent,
      recurse => true,
      force   => true,
      require => Exec['remove_windows_service'],
    }

  } else {
    fail("Unsupported kernel: ${facts['kernel']}")
  }
}

class bacula::storage(
    $db_backend,
    $director_server,
    $director_password,
    $storage_server,
    $storage_package,
    $mysql_package,
    $sqlite_package,
    $console_password,
    $template = 'bacula/bacula-sd.conf.erb'
  ) {

  $storage_name_array = split($storage_server, '[.]')
  $director_name_array = split($director_server, '[.]')
  $storage_name = $storage_name_array[0]
  $director_name = $director_name_array[0]

  $db_package = $db_backend ? {
    'mysql'  => $mysql_package,
    'sqlite' => $sqlite_package,
  }

  package { [$db_package, $storage_package]:
    ensure => installed,
  }

  # Configure the name and hostname for the Storage Daemon (i.e. this server)
  $safe_storage_hostname = $fqdn
  $safe_storage_name     = $hostname
  # And import the name of the Director from the node configuration
  $safe_director_hostname = $bacula_director_server
  $safe_director_name     = $bacula_director_server ? {
    /^([a-z0-9_-]+)\./ => $1,
    default            => $bacula_director_server
  }

  # Create the configuration for the Storage Daemon and make sure the directory
  # for the per-Client configuration is created before we run the realization
  # for the exported files below. Also make sure that the storage locations are
  # created along with the location for the default Device.
  file {
    '/etc/bacula/bacula-sd.conf':
      ensure  => 'present',
      owner   => 'bacula',
      group   => 'bacula',
      content => template($template),
      notify  => Service['bacula-sd'],
      require => Package[$db_package];
    '/etc/bacula/bacula-sd.d':
      ensure  => 'directory',
      owner   => 'bacula',
      group   => 'bacula',
      require => Package[$db_package];
  # Create an empty while which will make sure that the last line of
  # the bacula-sd.conf file will always run correctly.
    '/etc/bacula/bacula-sd.d/empty.conf':
      ensure  => 'present',
      owner   => 'bacula',
      group   => 'bacula',
      content => '# DO NOT EDIT - Managed by Puppet - DO NOT REMOVE',
      require => File['/etc/bacula/bacula-sd.d'];
   ['/mnt/bacula', '/mnt/bacula/default']:
      ensure  => 'directory',
      owner   => 'bacula',
      group   => 'tape',
      mode    => '0750';
  }

  # Register the Service so we can manage it through Puppet
  service {
    'bacula-sd':
      enable     => true,
      ensure     => running,
      require    => Package[$db_package],
      hasstatus  => true,
      hasrestart => true;
  }

  # Finally, realise all the virtual exported configruation from the clients
  # that this server needs to be configured to manage
  File <<| tag == "bacula_storage_$safe_storage_name" |>>
}

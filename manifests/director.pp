class bacula::director(
    $server,
    $password,
    $db_backend,
    $storage_server,
    $director_package,
    $mysql_package,
    $mail_to,
    $sqlite_package,
    $template = 'bacula/bacula-dir.conf',
    $use_console,
    $console_password
  ) {

  $storage_name_array = split($storage_server, '[.]')
  $director_name_array = split($server, '[.]')
  $storage_name = $storage_name_array[0]
  $director_name = $director_name_array[0]

  # Only support mysql or sqlite.
  # The given backend is validated in the bacula::config::validate class
  # before this code is reached.
  $db_package = $db_backend ? {
    'mysql'  => $mysql_package,
    'sqlite' => $sqlite_package,
  }
  
  package { [$db_package, $director_package]:
    ensure => installed,
  }

  # Configure the name and the hostname for the Director (i.e. this server)
  # and also set it to be the Client name/hostname as well for the File Deamon
  $safe_director_hostname = $fqdn
  $safe_director_name     = $hostname
  $safe_client_hostname   = $fqdn
  $safe_client_name       = $hostname
  # And import the details for the *DEFAULT* Storage Daemon, which will provide
  # the default storage Device and Pool configuration. Each client will be able
  # to define their own Storage Daemons if required and they will be imported
  # later on in the per-Client configuration
  $safe_storage_hostname = $bacula_storage_server
  $safe_storage_name     = $bacula_storage_server ? {
    /^([a-z0-9_-]+)\./ => $1,
    default            => $bacula_storage_server
  }

  # Create the configuration for the Director and make sure the directory for
  # the per-Client configuration is created before we run the realization for
  # the exported files below
  file {
    '/etc/bacula/bacula-dir.conf':
      ensure  => 'present',
      owner   => 'bacula',
      group   => 'bacula',
      content => template($template),
      notify  => Service['bacula-dir'],
      require => Package[$db_package];
    '/etc/bacula/bacula-dir.d':
      ensure  => 'directory',
      owner   => 'bacula',
      group   => 'bacula',
      require => Package[$db_package];
  # Create an empty while which will make sure that the last line of
  # the bacula-dir.conf file will always run correctly.
    '/etc/bacula/bacula-dir.d/00-header.conf':
      ensure  => file,
      owner   => 'bacula',
      group   => 'bacula',
      content => '# DO NOT EDIT - Managed by Puppet - DO NOT REMOVE',
      require => File['/etc/bacula/bacula-dir.d'];
  }

  # Register the Service so we can manage it through Puppet
  service {
    'bacula-dir':
      enable     => true,
      ensure     => running,
      require    => Package[$db_package],
      hasstatus  => true,
      hasrestart => true;
  }

  # Finally, realise all the virtual files created by all the clients that
  # this server needs to be configured to manage
  File <<| tag == "bacula_director_$safe_director_name" |>>
}

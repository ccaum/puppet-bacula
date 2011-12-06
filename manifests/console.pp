class bacula::console(
    $director_server,
    $director_password,
    $template = 'bacula/bconsole.conf.erb'
  ) {

  $director_name_array = split($server, '[.]')
  $director_name = $director_name_array[0]

  # Make sure the Console package is installed
  package {
    ['bacula-console']:
      ensure => 'latest';
  }

  # Using the above settings (and $bacula_console_password), write
  # the configuration for bacula-console (bconsole)
  file {
    '/etc/bacula/bconsole.conf':
      ensure  => 'present',
      owner   => 'bacula',
      group   => 'bacula',
      content => template($template),
      require => Package['bacula-console'];
  }
}

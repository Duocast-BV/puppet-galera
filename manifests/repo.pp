# Class galera::repo
#
# Installs the appropriate repositories from which percona packages
# can be installed
#
class galera::repo (
  $repo_vendor = $galera::vendor_type,
  $epel_needed = true,

  # Ubuntu-Debian/percona
  $apt_percona_repo_location = 'http://repo.percona.com/apt/',
  $apt_percona_repo_release = $facts['os']['distro']['codename'],
  $apt_percona_repo_repos = 'main',
  $apt_percona_repo_key = '4D1BB29D63D98E422B2113B19334A25F8507EFA5',
  $apt_percona_repo_key_server = 'keyserver.ubuntu.com',
  $apt_percona_repo_include_src = false,

  # Ubuntu-Debian/mariadb
  $apt_mariadb_repo_location = $facts['os']['name'] ? {
    'Debian' => 'http://mirror.aarnet.edu.au/pub/MariaDB/repo/5.5/debian',
    default  => 'http://mirror.aarnet.edu.au/pub/MariaDB/repo/5.5/ubuntu',
  },
  $apt_mariadb_repo_release = $facts['os']['distro']['codename'],
  $apt_mariadb_repo_repos = 'main',
  $apt_mariadb_repo_key = '199369E5404BD5FC7D2FE43BCBCB082A1BB943DB',
  $apt_mariadb_repo_key_server = 'keys.gnupg.net',
  $apt_mariadb_repo_include_src = false,

  # Ubuntu-Debian/codership
  $apt_codership_repo_location = $facts['os']['name'] ? {
    'Debian' => 'http://releases.galeracluster.com/debian',
    default  => 'http://releases.galeracluster.com/ubuntu',
  },
  $apt_codership_repo_release      = $facts['os']['distro']['codename'],
  $apt_codership_repo_repos        = 'main',
  $apt_codership_repo_key          = '44B7345738EBDE52594DAD80D669017EBC19DDBA',
  $apt_codership_repo_key_server   = 'keyserver.ubuntu.com',
  $apt_codership_repo_include_src  = false,

  #RedHat/percona
  $yum_percona_descr = "CentOS ${facts['os']['release']['major']} - Percona",
  $yum_percona_baseurl = "http://repo.percona.com/centos/${facts['os']['release']['major']}/os/${facts['os']['architecture']}/",
  $yum_percona_gpgkey = 'http://www.percona.com/downloads/percona-release/RPM-GPG-KEY-percona',
  $yum_percona_enabled = 1,
  $yum_percona_gpgcheck = 1,

  #RedHat/mariadb
  $yum_mariadb_descr = 'MariaDB Yum Repo',
  $yum_mariadb_enabled = 1,
  $yum_mariadb_gpgcheck = 1,
  $yum_mariadb_gpgkey = 'https://yum.mariadb.org/RPM-GPG-KEY-MariaDB',
  $yum_mariadb_baseurl = undef,

  #RedHat/codership
  $yum_codership_descr    = "CentOS ${facts['os']['release']['major']} - Codership",
  $yum_codership_baseurl  = "http://releases.galeracluster.com/centos/${facts['os']['release']['major']}/${facts['os']['architecture']}/",
  $yum_codership_gpgkey   = 'http://releases.galeracluster.com/GPG-KEY-galeracluster.com',
  $yum_codership_enabled  = 1,
  $yum_codership_gpgcheck = 1,
) {
  include galera::params

  if ! $yum_mariadb_baseurl {
    $lower = downcase($facts['os']['name'])
    $real_yum_mariadb_baseurl = "http://yum.mariadb.org/5.5-galera/${lower}${facts['os']['release']['major']}-amd64"
  } else {
    $real_yum_mariadb_baseurl = $yum_mariadb_baseurl
  }

  case $facts['os']['family'] {
    'Debian': {
      if ($facts['os']['name'] == 'Ubuntu') or ($facts['os']['name'] == 'Debian') {
        if ($repo_vendor == 'percona') {
          apt::source { 'galera_percona_repo':
            location => $apt_percona_repo_location,
            release  => $apt_percona_repo_release,
            repos    => $apt_percona_repo_repos,
            key      => {
              'id'     => $apt_percona_repo_key,
              'server' => $apt_percona_repo_key_server,
            },
            include  => {
              'src' => $apt_percona_repo_include_src,
            },
          }
        } elsif ($repo_vendor == 'mariadb') {
          apt::source { 'galera_mariadb_repo':
            location => $apt_mariadb_repo_location,
            release  => $apt_mariadb_repo_release,
            repos    => $apt_mariadb_repo_repos,
            key      => {
              'id'     => $apt_mariadb_repo_key,
              'server' => $apt_mariadb_repo_key_server,
            },
            include  => {
              'src' => $apt_mariadb_repo_include_src,
            },
          }
        } elsif ($repo_vendor == 'codership') {
          apt::source { 'galera_codership_repo':
            location => $apt_codership_repo_location,
            release  => $apt_codership_repo_release,
            repos    => $apt_codership_repo_repos,
            key      => {
              'id'     => $apt_codership_repo_key,
              'server' => $apt_codership_repo_key_server,
            },
            include  => {
              'src' => $apt_codership_repo_include_src,
            },
          }
        }
      }
      if ($repo_vendor == 'osp5') {
        fail('OSP5 is only supported on RHEL platforms.')
      }
    }

    'RedHat': {
      if $repo_vendor == 'percona' {
        yumrepo { 'percona':
          descr    => $yum_percona_descr,
          baseurl  => $yum_percona_baseurl,
          gpgkey   => $yum_percona_gpgkey,
          enabled  => $yum_percona_enabled,
          gpgcheck => $yum_percona_gpgcheck,
        } -> package { 'Percona-Server-shared-compat':
        }

        if $epel_needed {
          # Needed for socat package
          yumrepo { 'epel':
            mirrorlist     => "http://mirrors.fedoraproject.org/mirrorlist?repo=epel-${facts['os_maj_version']}&arch=${facts['os']['architecture']}",
            baseurl        => 'absent',
            failovermethod => 'priority',
            enabled        => '1',
            gpgcheck       => '1',
            gpgkey         => 'https://fedoraproject.org/static/0608B895.txt',
          }
        }
      }
      elsif $repo_vendor == 'mariadb' {
        yumrepo { 'mariadb':
          descr    => $yum_mariadb_descr,
          enabled  => $yum_mariadb_enabled,
          gpgcheck => $yum_mariadb_gpgcheck,
          gpgkey   => $yum_mariadb_gpgkey,
          baseurl  => $real_yum_mariadb_baseurl,
        }
        include galera::mariadb
      }
      elsif $repo_vendor == 'codership' {
        yumrepo { 'codership':
          descr    => $yum_codership_descr,
          enabled  => $yum_codership_enabled,
          gpgcheck => $yum_codership_gpgcheck,
          gpgkey   => $yum_codership_gpgkey,
          baseurl  => $yum_codership_baseurl,
        }
      }
    }
    default: {
      fail('This distribution is not currently supported by the galera module')
    }
  }
}

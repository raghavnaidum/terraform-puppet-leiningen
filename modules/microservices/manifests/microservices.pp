class microservices::microservices () {
     package { 'java-1.7.0-openjdk':
       ensure  => present,
       notify  => Package['python36'],
     }

     package { 'python36':
       ensure  => present,
     }

     
     exec { 'git_clone':
       command     => 'git clone https://github.com/ThoughtWorksInc/infra-problem.git',
       path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
       cwd         => '/usr/share/',
       notify      => Exec['wget_lein'],
       require     => Package['java-1.7.0-openjdk'],
     }


     exec { 'wget_lein':
       require     => Exec['git_clone'],
       command     => 'wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein',
       path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
       cwd         => '/usr/bin',
       notify      => File['/usr/bin/lein'],
     }

     file { '/usr/bin/lein':
	 require => Exec['wget_lein'],
         mode => 'a+x',
         notify  => Exec['lein'],
     }
     
     exec { 'lein':
       command     => 'lein',
       path        => [ '/usr/bin' ],
       notify      => Exec['make'],
     }

     exec { 'make':
       command     => 'make libs;make clean all',
       path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
       cwd         => '/usr/share/infra-problem',
       notify      => Exec['static_assets'],
     } 

      exec { 'static_assets':
       command     => '/usr/bin/python3.6 serve.py &',
       path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
       cwd         => '/usr/share/infra-problem/front-end/public',
       provider    => shell,
       notify      => File['/etc/systemd/system/quotes.service'],
     } 

        file { '/etc/systemd/system/quotes.service':
          ensure  => present,
          content => template("${module_name}/quotes.service.erb"),
          owner   => root,
          group   => root,
          mode    => '0644',
        } ~>
        exec { 'quotes-systemd-reload':
          command     => 'systemctl daemon-reload',
          path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
          refreshonly => true,
        }  ~>
        service { 'quotes':
          ensure    => 'running',
          enable    => true;
        } ->

        file { '/etc/systemd/system/newsfeed.service':
          ensure  => present,
          content => template("${module_name}/newsfeed.service.erb"),
          owner   => root,
          group   => root,
          mode    => '0644',
        } ~>
        exec { 'newsfeed-systemd-reload':
          command     => 'systemctl daemon-reload',
          path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
          refreshonly => true,
        }  ~>
        service { 'newsfeed':
          ensure    => 'running',
          enable    => true;
        } ->

        file { '/etc/systemd/system/front-end.service':
          ensure  => present,
          content => template("${module_name}/front-end.service.erb"),
          owner   => root,
          group   => root,
          mode    => '0644',
        } ~>
        exec { 'front-end-systemd-reload':
          command     => 'systemctl daemon-reload',
          path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
          refreshonly => true,
        }  ~>
        service { 'front-end':
          ensure    => 'running',
          enable    => true;
        }

 }

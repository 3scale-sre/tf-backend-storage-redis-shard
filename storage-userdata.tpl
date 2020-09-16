#cloud-config
hostname: ${HOSTNAME}
fqdn: ${HOSTNAME}.${DNS_ZONE}
packages:
    - docker
    - epel-release
    - vim

mounts:
    - [ /dev/nvme1n1, /mnt/redis-data ]

write_files:
    - path: /root/.docker/config.json
      owner: root:root
      permissions: '0600'
      content: |
        {
          "auths": {
            "quay.io": {
              "auth": "${THREESCALE_QUAY_DOCKER_AUTH_TOKEN}"
            }
          }
        }
    - path: /etc/NetworkManager/NetworkManager.conf
      owner: root:root
      permissions: '0644'
      content: |
        [keyfile]
        unmanaged-devices=interface-name:veth*
        [main]
        plugins=ifcfg-rh
        [logging]
    - path: /etc/systemd/system/node-exporter.service
      owner: root:root
      permissions: '0660'
      content: |
        [Unit]
        Description=Docker execution of node exporter
        Requires=docker.service
        After=docker.service

        [Service]
        User=root
        Restart=on-failure
        RestartSec=10
        Type=simple
        ExecStartPre=-/usr/bin/docker kill node-exporter
        ExecStartPre=-/usr/bin/docker rm node-exporter
        ExecStart=/bin/sh -c '/usr/bin/docker run --net=host -v /:/rootfs:ro -v /proc:/host/proc -v /sys:/host/sys -v /var/lib/prometheus/textfiles:/var/lib/prometheus/textfiles --name node-exporter quay.io/prometheus/node-exporter:v0.14.0 -collector.procfs /host/proc -collector.sysfs /host/sys -collector.filesystem.ignored-mount-points "^/(sys|proc|dev|host|etc)($|/)" -collector.textfile.directory /var/lib/prometheus/textfiles/'
        ExecStop=-/usr/bin/docker stop node-exporter

        [Install]
        WantedBy=multi-user.target

    - path: /etc/systemd/system/redis-exporter.service
      owner: root:root
      permissions: '0660'
      content: |
        [Unit]
        Description=Docker execution of redis exporter
        Requires=docker.service
        After=docker.service

        [Service]
        User=root
        Restart=on-failure
        RestartSec=10
        Type=simple
        ExecStartPre=-/usr/bin/docker kill redis-exporter
        ExecStartPre=-/usr/bin/docker rm redis-exporter
        ExecStart=/bin/sh -c 'docker run --name=redis-exporter -v /usr/local/etc/get_redis_conf.lua:/usr/local/etc/get_redis_conf.lua:ro --net=host oliver006/redis_exporter:v0.21.0 -script /usr/local/etc/get_redis_conf.lua'
        ExecStop=-/usr/bin/docker stop redis-exporter

        [Install]
        WantedBy=multi-user.target

    - path: /etc/systemd/system/redis.service
      owner: root:root
      permissions: '0660'
      content: |
        [Unit]
        Description=Docker execution of redis
        Requires=docker.service
        After=docker.service

        [Service]
        User=root
        Restart=on-failure
        RestartSec=10
        Type=simple
        ExecStartPre=-/usr/bin/docker kill redis
        ExecStartPre=-/usr/bin/docker rm redis
        ExecStart=/bin/sh -c 'docker run --name=redis --privileged -v /mnt/redis-data:/mnt/redis-data/ --network=host --ulimit nofile=10032:10032 quay.io/3scale/redis-backend:4.0.11 /etc/redis.conf --min-slaves-to-write 0'
        ExecStop=-/usr/bin/docker stop redis

        [Install]
        WantedBy=multi-user.target

    - path: /etc/profile.d/redis.sh
      owner: root:root
      permissions: '0660'
      content: |
       alias redis-cli='docker exec -it redis /usr/local/bin/redis-cli'

    - path: /etc/systemd/journald.conf
      owner: root:root
      permissions: '0660'
      content: |
        SystemMaxFileSize=100M
        SystemMaxUse=5G
        Storage=persistent
    - path: /var/spool/cron/root
      owner: root:root
      permissions: '0600'
      content: |

        */5 * * * * docker run --user=root --name=redis-slowlogs --rm -e REDIS_HOST=localhost -e ELASTICSEARCH_HOST=${ELASTICSEARCH_HOST} -e ELASTICSEARCH_INDEX=${ELASTICSEARCH_INDEX} --network=host quay.io/3scale/redis-slowlog-es:v0.0.1 >> /var/log/crons/slowlogs 2>&1
        */10 * * * * /usr/bin/flock -xon /tmp/redis-backup.lock -c 'docker run --user=root --name=redis-backups --rm --entrypoint=/usr/local/sbin/do_redis_backup.sh --network=host -e BCK_HOSTNAME=${HOSTNAME}.${DNS_ZONE} -e ENVIRONMENT=${BACKUPS_ENABLED} -e DEST_S3_BUCKET=${S3_BACKUPS_BUCKET_NAME} -e DEST_S3_PATH=${S3_BACKUPS_BUCKET_PREFIX} -v /mnt/redis-data:/mnt/redis-data/ quay.io/3scale/redis-backend:4.0.11' >> /var/log/crons/backups 2>&1
        0 * * * * docker run --user=root --name=redis-check-backups --rm --entrypoint=/usr/local/sbin/check-backups/check-backups.py -e HOSTNAME_CHECK=${HOSTNAME}.${DNS_ZONE} -e S3_BUCKET=${S3_BACKUPS_BUCKET_NAME} -e S3_PREFIX=${S3_BACKUPS_BUCKET_PREFIX} -e MIN_SIZE_CHECK=${S3_BACKUPS_BUCKET_MIN_SIZE_CHECK} -e PERIOD_CHECK_HOURS=${S3_BACKUPS_BUCKET_PERIOD_CHECK_HOURS} -v /var/lib/prometheus/textfiles/:/var/lib/prometheus/textfiles/ quay.io/3scale/redis-backend:4.0.11 >> /var/log/crons/check-backups 2>&1
        */5 * * * * docker run --name=github-ssh-keys --rm -v /home/3scale/.ssh/authorized_keys:/home/3scale/.ssh/authorized_keys -e GITHUB_ACCESS_TOKEN=${THREESCALE_GITHUB_SSH_KEY_TOKEN} -e GITHUB_ORGANIZATION=3scale -e GITHUB_TEAMS=operations,backend -e AUTHORIZED_KEYS_FILE=/home/3scale/.ssh/authorized_keys --user=$(id -u 3scale) orimarti/github-ssh-keys:0.0.1 >> /var/log/crons/github-ssh-keys 2>&1
    - path: /etc/sysctl.d/01-redis.conf
      owner: root:root
      permissions: '0600'
      content: |
        net.core.somaxconn = 65535
        vm.overcommit_memory = 1
    - path: /etc/rc.local
      owner: root:root
      permissions: '0755'
      content: |
        #!/bin/bash

        if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
          echo never > /sys/kernel/mm/transparent_hugepage/enabled
        fi

        if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
          echo never > /sys/kernel/mm/transparent_hugepage/defrag
        fi
        touch /var/lock/subsys/local
    - path: /usr/local/etc/get_redis_conf.lua
      owner: root:root
      permissions: '0755'
      content: |
        local result = {}
        local r = redis.call("CONFIG", "GET", "min-slaves-to-write")
        if r ~= nil then
            for _,v in ipairs(r) do
                table.insert(result, v)
            end
        else
        end
        return result

    - path: /etc/sudoers.d/91-3scale
      owner: root:root
      permissions: '0440'
      content: |
        3scale ALL=(ALL) NOPASSWD:ALL
    - path: /etc/selinux/container_ssh_home_t.te
      owner: root:root
      permissions: '0660'
      content: |
        module container_ssh_home_t 1.0;

        require {
            type container_t;
            type ssh_home_t;
            class file write;
            class file open;
        }
        allow container_t ssh_home_t:file {write open};

    - path: /etc/logrotate.d/crons
      owner: root:root
      permissions: '0644'
      content: |
        /var/log/crons/slowlogs
        /var/log/crons/backups
        /var/log/crons/check-backups
        /var/log/crons/github-ssh-keys
        {
            rotate 10
            missingok
            notifempty
            size 1k
            compress
        }

runcmd:
  - sleep 30
  - sysctl --system
  - service NetworkManager restart
  - systemctl restart systemd-journald
  - sleep 60 && blkid /dev/nvme1n1 | grep -q ext4 || mkfs -t ext4 -L backup /dev/nvme1n1
  - echo never > /sys/kernel/mm/transparent_hugepage/enabled
  - echo never > /sys/kernel/mm/transparent_hugepage/defrag
  - mount -a
  - mkdir -p /mnt/redis-data/logs
  - chcon -Rt svirt_sandbox_file_t /mnt/redis-data/
  - chcon -Rt svirt_sandbox_file_t
  - chown 1001:1001 /mnt/redis-data
  - chown 1001 /mnt/redis-data/logs
  - mkdir /etc/systemd/system/docker.service.wants/
  - mkdir -p /var/lib/prometheus/textfiles
  - chcon -Rt svirt_sandbox_file_t /var/lib/prometheus/textfiles/
  - ln -s /etc/systemd/system/node-exporter.service /etc/systemd/system/docker.service.wants/
  - ln -s /etc/systemd/system/redis-exporter.service /etc/systemd/system/docker.service.wants/
  - ln -s /etc/systemd/system/redis.service /etc/systemd/system/docker.service.wants/
  - systemctl enable docker
  - systemctl daemon-reload
  - sleep 30 && systemctl restart --no-block docker
  - adduser -U 3scale
  - mkdir /home/3scale/.ssh/
  - touch /home/3scale/.ssh/authorized_keys
  - chown -R 3scale:3scale /home/3scale/.ssh/
  - chmod 0600 /home/3scale/.ssh/authorized_keys
  - checkmodule -M -m /etc/selinux/container_ssh_home_t.te -o /etc/selinux/container_ssh_home_t.mod
  - semodule_package -o /etc/selinux/container_ssh_home_t.pp -m /etc/selinux/container_ssh_home_t.mod
  - semodule -i /etc/selinux/container_ssh_home_t.pp
  - mkdir -p /var/log/crons/
  - sed -i "s/#compress/compress/g" /etc/logrotate.conf

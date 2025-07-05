cat /etc/os-release | grep -E 'ubuntu'
if [ $? -eq 0 ]; then
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \

  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
elif [ $? -eq 1 ]; then
    dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
    dnf install -y docker-ce
else
    echo "Unsupported OS. Exiting."
    exit 1
fi


usermod -aG docker $USER
newgrp docker

cat > /etc/docker/daemon.json << EOF
{
  "insecure-registries":["docker.rockylinux.cn"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
     "max-size": "100m",
     "max-file": "10"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "default-shm-size": "128M",
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 10,
  "debug": false
}
EOF

systemctl daemon-reload
systemctl enable docker --now


echo "Configuring Docker proxy settings..."
mkdir -p /etc/systemd/system/docker.service.d
touch /etc/systemd/system/docker.service.d/proxy.conf
cat > /etc/systemd/system/docker.service.d/proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=http://192.168.3.14:20800/"
Environment="HTTPS_PROXY=http://192.168.3.14:20800/"
Environment="NO_PROXY=localhost,127.0.0.1,.example.com"
EOF

systemctl daemon-reload
systemctl restart docker

echo "Configuring containerd proxy settings..."
mkdir -p /etc/systemd/system/containerd.service.d
touch /etc/systemd/system/containerd.service.d/proxy.conf
cat > /etc/systemd/system/containerd.service.d/proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=http://192.168.3.14:20800/"
Environment="HTTPS_PROXY=http://192.168.3.14:20800/"
Environment="NO_PROXY=localhost,127.0.0.1,.example.com"
EOF

containerd config default | sudo tee /etc/containerd/config.toml
sed -i 's|registry.k8s.io/pause:3.8|registry.aliyuncs.com/google_containers/pause:3.10|g' /etc/containerd/config.toml


systemctl daemon-reload
systemctl restart containerd
echo "Docker installation and configuration completed."
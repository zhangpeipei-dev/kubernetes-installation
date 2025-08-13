## Jenkinsci docker container is failing to update the plugins behind proxy.

Create a proxy.xml file in the jenkins_home directory. This directory can be found at /var/jenkins_home in the container. If you are running the container with the mounted volume you should create this file in that volume
<?xml version='1.1' encoding='UTF-8'?> <proxy> <name>YourProxyServerIP</name> <port>8080</port> <noProxyHost>10.1.*</noProxyHost> <secretPassword>{AQAAABAAAAAQWFrQGKBJbjtkTNGDUdLFx+erWaL0lR/oQKAmPKrvgTU=}</secretPassword> </proxy>

Change the IP and Port with your proxy server details
Run the container and you should be able to install and update the plugins

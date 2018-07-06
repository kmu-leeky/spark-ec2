#!/bin/bash
# Creates an AMI for the Spark EC2 scripts starting with a stock Amazon
# Linux AMI.
# This has only been tested with Amazon Linux AMI 2014.03.2

set -e

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Dev tools
sudo yum install -y java-1.8.0-openjdk-devel gcc gcc-c++ ant cmake
# Perf tools
sudo yum install -y dstat iotop strace sysstat htop perf
sudo debuginfo-install -q -y glibc
sudo debuginfo-install -q -y kernel
sudo yum --enablerepo='*-debug*' install -q -y java-1.8.0-openjdk-debuginfo.x86_64

# PySpark and MLlib deps
sudo yum install -y  python-matplotlib python-tornado scipy libgfortran
# SparkR deps
sudo yum install -y R
# Other handy tools
sudo yum install -y pssh
# Ganglia
sudo yum install -y ganglia ganglia-web ganglia-gmond ganglia-gmetad

# Root ssh config
sudo sed -i 's/PermitRootLogin.*/PermitRootLogin without-password/g' \
  /etc/ssh/sshd_config
sudo sed -i 's/disable_root.*/disable_root: 0/g' /etc/cloud/cloud.cfg

# Set up ephemeral mounts
sudo sed -i 's/mounts.*//g' /etc/cloud/cloud.cfg
sudo sed -i 's/.*ephemeral.*//g' /etc/cloud/cloud.cfg
sudo sed -i 's/.*swap.*//g' /etc/cloud/cloud.cfg

echo "mounts:" >> /etc/cloud/cloud.cfg
echo " - [ ephemeral0, /mnt, auto, \"defaults,noatime\", "\
  "\"0\", \"0\" ]" >> /etc/cloud.cloud.cfg

for x in {1..23}; do
  echo " - [ ephemeral$x, /mnt$((x + 1)), auto, "\
    "\"defaults,noatime\", \"0\", \"0\" ]" >> /etc/cloud/cloud.cfg
done

# Edit bash file
echo "export PS1=\"\\u@\\h \\W]\\$ \"" >> /root/.bash_profile
echo "export JAVA_HOME=/usr/lib/jvm/java-1.8.0" >> /root/.bash_profile
echo "export M2_HOME=/usr/local/maven/" >> /root/.bash_profile
echo "export PROTOC=/usr/local/bin/protoc" >> /root/.bash_profile
echo "export PATH=\$PATH:/usr/local/bin:\$M2_HOME/bin:/root/spark/bin:/root/ephemeral-hdfs/bin" >> /root/.bash_profile

source /root/.bash_profile

# Create /usr/bin/realpath which is used by R to find Java installations
# NOTE: /usr/bin/realpath is missing in CentOS AMIs. See
# http://superuser.com/questions/771104/usr-bin-realpath-not-found-in-centos-6-5
echo '#!/bin/bash' > /usr/bin/realpath
echo 'readlink -e "$@"' >> /usr/bin/realpath
chmod a+x /usr/bin/realpath`

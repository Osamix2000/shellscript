#/bin/bash

cd ~
yum -y remove htop
yum -y install git automake autoconf gcc ncurses ncurses-devel lm_sensors lm_sensors-devel libunwind libunwind-devel hwloc hwloc-devel libcap libcap-devel
git clone https://github.com/htop-dev/htop.git
cd htop
./autogen.sh && ./configure && make && make install
cd ~
rm -rf htop
rm -rf htop-install.sh
echo ====================================================================
echo 最新のhtopをインストールしました。
echo 最新のhtopを利用するには一度sshから切断した後、再度接続し直してください。
echo ====================================================================

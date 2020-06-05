#!/bin/bash
set -x

# Install prepreqs
sudo yum update -y
sudo yum install -y autoconf \
    automake \
    bison \
    flex \
    gcc \
    gcc-c++ \
    gdbm-devel \
    gettext \
    git \
    kernel-devel \
    libffi-devel \
    libyaml-devel \
    m4 \
    make \
    ncurses-devel \
    openssl-devel \
    patch \
    readline-devel \
    rpm-build \
    sudo \
    wget \
    zlib-devel
if grep -E 'PRETTY_NAME.*Amazon Linux 2' /etc/os-release; then
  sudo amazon-linux-extras install -y ruby2.4
else
  sudo yum install -y ruby
fi

# Add omnibus and ec2-user to sudoers
sudo echo 'omnibus  ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers
sudo echo 'ec2-user  ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers

# Chef 15.11.3 RPM
echo `date`
sudo systemctl stop chef-client
sudo yum remove omnibus-toolchain -y
sudo yum remove chef -y
sudo yum remove cinc -y

set -xeuo pipefail #echo on, stop on failures

# Ruby 2.7.1
cd
rm -rf ~/.bundle
rm -rf ~/.gem
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
RUBYVERSION=$(ruby --version)
if [[ $RUBYVERSION =~ 2.7.1 ]]; then
  echo "Using existing Ruby 2.7.1 provided by rbenv"
else
  echo "Building Ruby 2.7.1"
  rm -rf ~/.rbenv
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  cd ~/.rbenv && src/configure && make -C src
  mkdir plugins
  git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
  rbenv install 2.7.1
  rbenv global 2.7.1
  eval "$(rbenv init -)"
fi

# # Omnibus-Toolchain
grep -q omnibus /etc/group || sudo groupadd omnibus
grep -q omnibus /etc/passwd || sudo useradd -g omnibus omnibus
cd
rm -rf ~/omnibus-toolchain
sudo rm -rf /opt/omnibus-toolchain /var/cache/omnibus
sudo mkdir /opt/omnibus-toolchain && sudo chmod -R 777 /opt/omnibus-toolchain
sudo mkdir /var/cache/omnibus && sudo chmod -R 777 /var/cache/omnibus
sudo chown omnibus:omnibus -R /opt/omnibus-toolchain
sudo chown omnibus:omnibus -R /var/cache/omnibus
git clone https://github.com/chef/omnibus-toolchain.git
cd omnibus-toolchain
sed -i "s/chef\/omnibus'/mattray\/omnibus', :branch => 'open_uri'/" Gemfile
bundle config set without development
bundle install --path=.bundle
bundle exec omnibus build omnibus-toolchain -l internal
cp ~/omnibus-toolchain/pkg/omnibus-toolchain*rpm ~/
sudo rm -rf /opt/omnibus-toolchain
sudo rpm -Uvh ~/omnibus-toolchain*rpm
sudo chown omnibus:omnibus -R /opt/omnibus-toolchain
export PATH="/opt/omnibus-toolchain/bin:$PATH"

# Chef 15.11.3
cd
sudo chmod a+w /opt  # TODO figure out why this is needed
rm -rf ~/chef-15.11.3 ~/v15.11.3.tar.gz
sudo rm -rf /opt/chef
sudo mkdir /opt/chef
sudo chown omnibus:omnibus -R /opt/chef
wget https://github.com/chef/chef/archive/v15.11.3.tar.gz
tar -xzf v15.11.3.tar.gz
cd ~/chef-15.11.3/omnibus/
bundle config set without development
bundle install --path=.bundle
bundle exec omnibus build chef -l internal
cp ~/chef-15.11.3/omnibus/pkg/chef*rpm ~/

# Cinc 15.11.3
cd
sudo rm -rf ~/cinc /opt/chef /opt/cinc ~/client-master.tar.gz
sudo mkdir /opt/cinc
sudo chown omnibus:omnibus -R /opt/cinc
wget https://gitlab.com/cinc-project/client/-/archive/cinc-15/client-master.tar.gz
tar -xzf client-master.tar.gz
mv client-cinc-15-87eff194e4d9deeb134228131990944522b1130e cinc
cd cinc
git config --global user.email "tilne@amazon.com"
git config --global user.name "Tim Lane"
git clone -q -b v15.11.3 https://github.com/chef/chef.git
# patch patch.sh
sed -e '/^source/ s/^/# /' patch.sh > patch2.sh
sed -e '/^rm/,+3 s/^/# /' patch2.sh > patch3.sh
bash patch3.sh 15.11.3
cd chef/omnibus/
bundle config set without development
bundle install --path=.bundle
bundle exec omnibus build cinc -l internal
cp ~/cinc/chef/omnibus/pkg/cinc*rpm ~/

echo "15.11.3 Complete!"
echo `date`

# frozen_string_literal: true

resource_name :install_pyenv
provides :install_pyenv

# Resource to create a Python virtual environment for a given user

property :user, String, name_property: true
property :python_version, String, required: true
property :install_path, String, default: lazy { ::File.join(::File.expand_path("~#{user}"), '.pyenv') }

default_action :run

action :run do
  unless ::File.directory?(::File.join(new_resource.install_path, 'versions', new_resource.python_version))
    # Install required packages
    package node['cfncluster']['pyenv_packages']

    # Install pyenv
    git new_resource.install_path do
      repository 'https://github.com/pyenv/pyenv.git'
      reference  'master'
      user       new_resource.user
      group      new_resource.user
      action     :checkout
    end

    # Install pyenv's virtualenv plugin
    git ::File.join(new_resource.install_path, 'plugins', 'virtualenv') do
      repository  'https://github.com/pyenv/pyenv-virtualenv'
      reference   'master'
      user        new_resource.user
      group       new_resource.user
      action      :checkout
    end

    # Install desired version of python
    pyenv_command "install #{new_resource.python_version}" do
      user new_resource.user
      pyenv_path new_resource.install_path
    end
  end
end

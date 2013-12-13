# Fabric deploy script
#
# Install pip with:    sudo apt-get install python-pip
# Install fabric with: sudo pip install fabric
from __future__ import with_statement
from fabric.api import *

env.roledefs = {
  "staging": ["staging.adefy.com:58124"],
  "production": ["app.adefy.com:48723"]
}

env.user = "cris"
env.key_filename = "~/.ssh/id_rsa"

adefy_path = "/var/adefy/"
adefy_repo = "ssh://gitlab@git.spectrumit.eu:11235/adefy/adefycloud.git"

# Sets up the environment and folder on the remote server
def _setup(branch):
  with cd(adefy_path):

    # Clean and initialize repo
    run("rm * .git .gitignore .gitmodules -rf")
    run("git init .")
    run("git remote add origin " + adefy_repo)
    run("git pull origin master")
    run("git fetch origin " + branch + ":" + branch)
    run("git checkout " + branch)
    run("git submodule init")

    # Install global dependencies
    sudo("npm install -g codo grunt-cli forever")

# Updates server packages
@roles("production", "staging")
def update_servers():
  sudo("bash -c 'apt-get update && apt-get upgrade'")

# Production
@roles("production")
def setup_production():
  _setup("production")

@roles("production")
def deploy():
  with cd(adefy_path):

    # Update
    run("git checkout production")
    run("git pull origin production")
    run("git submodule update")

    # Re-build line
    run("cd line && npm install")
    run("cd line && grunt")

    # Install any new modules
    run("npm install")

    # Build
    run("grunt full")

    # Test (abort on fail)
    #run("grunt test")

    # Deploy
    run("grunt deploy")

    # Restart
    run("forever restart production/adefy.js")

# Staging
@roles("staging")
def setup_staging():
  _setup("staging")

@roles("staging")
def stage():
  with cd(adefy_path):

    # Update
    run("git checkout staging")
    run("git pull origin staging")
    run("git submodule update")

    # Re-build line
    run("cd line && npm install")
    run("cd line && grunt")

    # Install any new modules
    run("npm install")

    # Build
    run("grunt full")

    # Test (abort on fail)
    #run("grunt test")

    # Stage
    run("grunt stage")

    # Restart
    run("forever restart staging/adefy.js")

# Forever controls
@roles("staging")
def stage_up():
  with cd(adefy_path):
    run("forever start staging/adefy.js")

@roles("staging")
def stage_restart():
  with cd(adefy_path):
    run("forever restart staging/adefy.js")

@roles("staging")
def stage_down():
  with cd(adefy_path):
    run("forever stop staging/adefy.js")

@roles("production")
def production_up():
  with cd(adefy_path):
    run("forever start production/adefy.js")

@roles("production")
def production_restart():
  with cd(adefy_path):
    run("forever restart production/adefy.js")

@roles("production")
def production_down():
  with cd(adefy_path):
    run("forever stop production/adefy.js")

@roles("production", "staging")
def status():
  with cd(adefy_path):
    run("forever list")

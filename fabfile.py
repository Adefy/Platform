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
adefy_repo = "git@bitbucket.org:spectrumit/adefyplatform.git"

# Sets up the environment and folder on the remote server
def _setup(branch):
  with cd(adefy_path):

    # Clean and initialize repo
    run("rm * .git .gitignore .gitmodules -rf")
    run("git init .")
    run("git remote add origin " + adefy_repo)
    run("git pull origin master")

    run("git branch " + branch)
    run("git pull origin " + branch)

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

    # Install any new modules
    run("npm install")

    # Test (abort on fail)
    run("grunt deployTest")

    # Deploy
    run("grunt deploy")

    # Restart
    run('bash -c "(forever stop buildProduction/adefy.js) || true"')
    run("forever start buildProduction/adefy.js")

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

    # Install any new modules
    run("npm install")

    # Test (abort on fail)
    run("grunt deployTest")

    # Stage
    run("grunt stage")

    # Restart
    run('bash -c "(forever stop buildStaging/adefy.js) || true"')
    run("forever start buildStaging/adefy.js")

# Forever controls
@roles("staging")
def stage_up():
  with cd(adefy_path):
    run("forever start buildStaging/adefy.js")

@roles("staging")
def stage_restart():
  with cd(adefy_path):
    run("forever restart staging/adefy.js")

@roles("staging")
def stage_down():
  with cd(adefy_path):
    run("forever stop buildStaging/adefy.js")

@roles("production")
def production_up():
  with cd(adefy_path):
    run("forever start buildProduction/adefy.js")

@roles("production")
def production_restart():
  with cd(adefy_path):
    run("forever restart buildProduction/adefy.js")

@roles("production")
def production_down():
  with cd(adefy_path):
    run("forever stop buildProduction/adefy.js")

@roles("production", "staging")
def status():
  with cd(adefy_path):
    run("forever list")
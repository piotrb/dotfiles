#!python3

import yaml
from os.path import expanduser
import configparser
import sys

config = yaml.safe_load(open(expanduser("~/.aws/sso-gen-config.yaml")))

aws_config = configparser.ConfigParser()

read = aws_config.read([expanduser("~/.aws/config")])

def normalize_config():
  if not "default" in config:
    config["default"] = {}

  if not "sso_sessions" in config:
    config["sso_sessions"] = {}

  for name in config["sso_sessions"].keys():
    if not "sso_registration_scopes" in config["sso_sessions"][name]:
      config["sso_sessions"][name]["sso_registration_scopes"] = "sso:account:access"

  if not "sso_session" in config["default"]:
      if len(config["sso_sessions"].keys()) > 0:
        config["default"]["sso_session"] = list(config["sso_sessions"].keys())[0]
      else:
        raise Exception("No sso_session defined in config")

  if not "accounts" in config:
    config["accounts"] = {}
  
  for name in config["accounts"].keys():
    if not "roles" in config["accounts"][name]:
      if "default_roles" in config:
        config["accounts"][name]["roles"] = config["default_roles"]
      else:
        raise Exception(f"No roles defined for account {name}, and no default_roles defined")
    if "add_roles" in config["accounts"][name]:
      config["accounts"][name]["roles"] += config["accounts"][name]["add_roles"]
      del config["accounts"][name]["add_roles"]

def add_section(section_name, delete=False):
  if delete:
    if aws_config.has_section(section_name):
      aws_config.remove_section(section_name)
    aws_config.add_section(section_name)
  else:
    if not aws_config.has_section(section_name):
      aws_config.add_section(section_name)

normalize_config()

add_section("default")
aws_config.set("default", "sso_session", config["default"]["sso_session"])

for name, info in config['sso_sessions'].items():
  section_name = f"sso-session {name}"
  add_section(section_name, delete=True)
  for key, value in info.items():
    aws_config.set(section_name, key, value)

for name, info in config['accounts'].items():
    account_id = info['id']
    for role in info['roles']:
        section_name = f"profile {role}-{name}"
        add_section(section_name, delete=True)
        aws_config.set(section_name, "credential_process", f"aws configure export-credentials --profile {role}-{name}-m")

        section_name = f"profile {role}-{name}-m"
        add_section(section_name, delete=True)
        
        aws_config.set(section_name, "sso_session", config["default"]["sso_session"])
        aws_config.set(section_name, "sso_account_id", str(account_id))
        aws_config.set(section_name, "sso_role_name", role)

aws_config.write(sys.stdout)

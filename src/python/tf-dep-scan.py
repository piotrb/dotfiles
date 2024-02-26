import json
import os
from collections import defaultdict
from prettytable import PrettyTable

# Define the base directory
base_dir = 'modules'

# Function to construct base and full URLs based on source type, source, and sub-module
def construct_urls(source_type, source, sub_module):
    base_url = ''
    full_url = ''
    if source_type == 'module_registry':
        base_url = f"https://registry.terraform.io/modules/{source}"
        if sub_module:
            # Adjust submodule path as needed
            sub_path = "latest/submodules" + (sub_module.replace("modules/", "/") if "modules/" in sub_module else f"/{sub_module}")
            full_url = f"{base_url}/{sub_path}"
        else:
            full_url = base_url
    elif source_type == 'git':
        if source.startswith('git::git@'):
            base_url = f"https://{source.replace('git::git@', '').replace(':', '/')}"
        else:
            base_url = f"https://{source}"
        full_url = base_url
        if sub_module:
            full_url += f"/tree/main/{sub_module}"
    else:
        base_url = ''
        full_url = ''
    return base_url, full_url

# Updated functions for source classification and version/sub-module splitting

def classify_module_source(source):
    sub_module = None
    if '//' in source:
        source, sub_module = source.split('//', 1)
    source_type = 'local'
    if source.startswith('./') or source.startswith('../'):
        source_type = 'local'
    elif source.startswith('git::') or 'github.com' in source:
        source_type = 'git'
    else:
        source_type = 'module_registry'
    return source_type, source, sub_module

def split_version_submodule(version):
    sub_module = None
    if '//' in version:
        version, sub_module = version.split('//', 1)
    return version, sub_module

# Data structure to hold the dependency information

providers_dependencies = defaultdict(list)
modules_dependencies = defaultdict(lambda: defaultdict(lambda: defaultdict(list)))

# Scan the modules directory

for module_name in os.listdir(base_dir):
    module_path = os.path.join(base_dir, module_name)
    deps_file_path = os.path.join(module_path, 'module-deps.json')
    if os.path.isdir(module_path) and os.path.exists(deps_file_path):
        with open(deps_file_path) as f:
            deps = json.load(f)
            for provider in deps.get('providers', []):
                if provider['name'] != "terraform":
                    version = (provider.get('version') or '').strip()
                    alias = provider.get('alias', '')
                    providers_dependencies[provider['name']].append((alias, version, module_name))
            for module in deps.get('modules', []):
                source_type, source, sub_module_source = classify_module_source(module['source'])
                version, sub_module_version = split_version_submodule(module.get('version', 'N/A'))
                sub_module = sub_module_version or sub_module_source
                if source_type != 'local':
                    base_url, full_url = construct_urls(source_type, source, sub_module)  # Construct base and full URLs
                    modules_dependencies[source_type][source][version].append((module_name, sub_module or '', version, base_url, full_url))

# Display Providers Information

providers_table = PrettyTable()
providers_table.field_names = ["Provider", "Alias", "Version", "Module"]
providers_table.align = "l"
for provider, versions in providers_dependencies.items():
    for alias, version, module in versions:
        providers_table.add_row([provider, alias or '', version or '', module])
print("Providers:")
print(providers_table)

# Display Modules Information

modules_table = PrettyTable()
modules_table.field_names = ["Source Type", "Source", "Sub-Module", "Version", "Module", "URL", "Full URL"]  # Include both URL columns
modules_table.align = "l"
for source_type, sources in modules_dependencies.items():
    for source, versions in sources.items():
        for version, modules in versions.items():
            for module, sub_module, version, base_url, full_url in modules:
                modules_table.add_row([source_type, source, sub_module or '', version, module, base_url, full_url])
print("\nModules:")
print(modules_table)

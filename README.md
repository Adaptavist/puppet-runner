# puppet-runner

Executable gem that composes hiera configuration and facts and execute puppet apply 

## Installation

    $ gem install puppet-runner

## Usage

*  puppet-runner (prepare|start|all) [-c CONFIG_DIR] [-t TEMPLATES] [-d DESTINATION_DIR] [-f FACTS_DEST] [-s SERVERNAME] [-r PUPPETFILE_CONFIG] [-o PUPPETFILE_OUTPUT_PATH] [-e EYAML_KEY_PATH]
*  puppet-runner -h | --help


### Config files description and usage

Eyaml files can also be used. Use the -e option to specify the directory that contains your eyaml encryption key pair,
the default if no directory is specified is /etc/puppet/config  
Eyaml expects the files to be called public_key.pkcs7.pem and private_key.pkcs7.pem


#### CONFIG_DIR

Must contain configuration files based on that the final hiera configuration and custom facts file will be composed.

If -s "SERVERNAME" option is provided then the app will search for SERVERNAME.yaml and SERVERNAME_facts.yaml in the CONFIG_DIR directory. If not then fact hostname is looked up and "hostname".yaml and "hostname"_facts.yaml are used.

"hostname".yaml - contains configuration for functional composition and prefix setup for each of the functionality.

##### Example functionality config file

```

---
functionalities:
  0_global:
    - baseusers
  1_app:
    - confluence: "conf1_"
    - confluence: "conf2_"
    - jira
  2_connectors:
    - connector_proxy:
        "application_": "conf1_"
        "connector_": "connector1_"
    - connector_proxy: 
        "application_": "conf1_"
        "connector_": "connector2_"
    - connector_proxy: 
        "application_": "conf2_"
        "connector_": "connector3_"
    - connector_proxy: 
        "application_": "jira_"
        "connector_": "connector4_"
  3_database:
    - mysql: "jira1_"
    - mysql: "confluence1_"
    - mysql: "confluence2_"

```

Setup explained

This setup will result into server setup with 2 confluence instances (properties can be setup via facts with prefix conf1_  and conf2_) one jira instance (facts with prefix jira1_) with 2 connector_proxy configs for instance conf1_ (connector1_ and connector2_), one connector for conf2_ and one for jira1_ instance. 3 mysql databases will be created and template baseusers added. The result parametrized hiera setup has to be configured by providing instance specific prefixed facts in "hostname"_facts.yaml

General description

File has to contain hash of functionalities. Keys are number prefixed placeholders aggregating different sets of functionalities, number-prefixed keys are used for ordering purposes. Values of those keys are arrays of different functionalities to be included for this hostname. Each key must correspond to yaml file in "TEMPALTES"/templates directory to be included. There also has to be corresponding facts file in "TEMPALTES"/defaults folder. 

There are 3 ways to configure prefixes for each required functionality. 

- No prefix substitution

```
1_app:
    - jira

```

Template file "TEMPALTES"/templates/jira.yaml and "TEMPALTES"/defaults/jira.yaml will be added with no prefix substitution to the result hiera config. User will have to provide required facts prefixed with jira_ to "hostname"_facts.yaml to uniquely identify the jira instance facts.

- Simple prefix substitution

```
3_database:
    - mysql: "jira1_"
```

Template file "TEMPALTES"/templates/mysql.yaml and default facts file for mysql will be added to result config with all prefixes as defined in template file substituted to provided value, in this example jira1_. So the required facts for this instance in "hostname"_facts.yaml must contain facts prefixed with jira1_*. In example provided those would be jira1_database_name, jira1_database_user and jira1_database_pass to uniquelly identify the facts for this instance of mysql db. 

- Custom prefix substitution

```
- connector_proxy:
    "application_": "conf1_"
    "connector_": "connector1_"
```

With this setup we define prefix -> substitution_string pair for each prefix in template file. This setup will reduce number of facts user has to provide to achieve required setup. In an example above substituting "application_" prefix with "conf1_" will result to assigning this connector to "conf1_instance_name" instance of confluence, so we do not have to provide "connector1_instance_name" and can reuse existing one from conf1 setup.

"hostname"_facts.yaml - must contain all prefixed custom facts to customize the setup 

#### TEMPLATES
Must contain 2 subdirectories.
- templates - template yaml files

Each template contains:
* prefixes - list of prefixes to support inclusion of multiple instances of the template and their unique identification
* classes - list of classes to include for this template
* required_fields - list of required facts for this setup, in case not provided the processing will fail with warning
* template specific parametrized setup - see examples provided
* dependencies - all modules required to include to Puppetfile, must contain all recursive deps.

- defaults - default values for facts

In case the value for the fact is nil it will become required fact. 

#### DESTINATION_DIR

Destination directory for composed hiera setup. Usually pointing to /etc/puppet/hiera to be loaded by hiera backends for further processing like applying secrets.

#### FACTS_DEST

Destination directory for composed facts setup. Usually pointing to /etc/puppet/environments/production/modules/hosts/facts.d to be loaded by puppet apply.

#### PUPPETFILE_CONFIG

Config file with puppet modules details. Modules dependencies are referenced in templates config via key in dependencies array.

Format:

```
mkhomedir: 
    name: 'adaptavist/mkhomedir'
    repo: 'ssh://git@stash.adaptavist.com:7999/pup/puppet-mkhomedir.git'
    repo_type: "tag"
    ref_value: '0.1.2'
    ref_type: 'git'
```

#### PUPPETFILE_OUTPUT_PATH

Path to output Puppetfile. 

### Options:

*  -h --help                                       Show this screen.
*  -s SERVERNAME --servername SERVERNAME           Custom identification of server, hostname fact if not provided
*  -c CONFIG_DIR --config_dir CONFIG_DIR           Hiera configuration directory, must ontain "hostname".yaml and "hostname"_facts.yaml
*  -d DESTINATION_DIR --dest_dir DESTINATION_DIR   Directory for result hiera config.
*  -t TEMPLATES --templates TEMPLATES              Directory containing templates and defaults folder with functionality templates and default facts
*  -f FACTS_DEST --facts_dest_dir FACTS_DEST       Destination directory to store result facts
*  -r PUPPETFILE_CONFIG --puppetfile_config puppetfile_config                Puppetfile composition config file
*  -o PUPPETFILE_OUTPUT_PATH --puppetfile_output_path PUPPETFILE_OUTPUT_PATH Result Puppetfile path
*  -e EYAML_KEY_PATH --eyaml_key_pair EYAML_KEY_PATH                         Path to eyaml encryption key pair

Commands:

*  all           Runs the following commands prepare, start 
*  start         Runs puppet apply 
*  prepare       Creates result hiera config as a composition of functionalities based on config, merges provided facts with defaults


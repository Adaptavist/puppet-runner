# puppet-runner

Executable gem that composes hiera configuration and facts and execute puppet apply 

## Installation

    $ gem install puppet-runner

## Usage

*  puppet-runner (prepare|all) [-c CONFIG_DIR] [-t TEMPLATES] [-d DESTINATION_DIR] [-f FACTS_DEST] [-s SERVERNAME] [-r PUPPETFILE_CONFIG] [-o PUPPETFILE_OUTPUT_PATH] [-e EYAML_KEY_PATH] [-x CUSTOM_FACTS_DIR]
*  puppet-runner start [-p PUPPET_APPLY]
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

### Fact Metadata

The defaults file contains all the facts (variables) that are needed to run the tempalte, the basic format of this is:
```
fact_name: 'fact_value'
```

So in this instance fact_name will have a default value of fact_value, which can be overiden by the user in their own facts file.

However it is also possible to add metadata to the facts by changing the format, the current metadata is `comment` and `type`, this extened format looks like:

```
fact_name:
    value: 'fact_value'
    comment: 'this is an important fact'
    type: 'string'
```

The two metadata values are:
`comment` - This is a description for the fact to help identify what it is for, it is added above the fact in the reultant facts files written by puppet-runner
`type` - This identifies the data type of the fact, by default if this meatadata is not set the value defaults to `string`, current valid types are:
**string**
**boolean**
**nilable**

### Fact Types

As mentioned above it is possible to assign a "type" metadata element to each fact, the reasons is that facter delivers all its data as a string, this can cause issues so the "type" metadata allows puppet-runner to do something special for other data typs:

#### string

All data is passed by default as a string, setting the type to string does not do anythign special

#### boolean

If the type is set to boolean this tells puppet-runner that we want to pass in true boolean values, a conversion from the string value into true boolean is attempted.  If the conversions is successfull the fact reference in the final compiled hiera document (/etc/puppet/hiera/<HOSTNAME>.eyaml) would be replaced with the actual boolean value so that puppet does not recive its string representation.

Example:

Template
```
---
  
prefixes:
    - yum_

classes:
    - yum

dependencies:
  - yum
  - puppi

yum::defaultrepo: "%{::yum_defaultrepo}"
```

If the defaults does not use metadata (or uses a type of string) and the facts are set as below
```
---
  
yum_defaultrepo: "true"
```

Then the value writen into /etc/puppet/hiera/<HOSTNAME>.eyaml would be 

```
yum::defaultrepo: "%{::yum_defaultrepo}"
```

Whereas if the default was set to boolean as below:
```
---
  
yum_defaultrepo: 
  value: "true"
  type: "boolean"
```

Then the value writen into /etc/puppet/hiera/<HOSTNAME>.eyaml would be 

```
yum::defaultrepo: true
```

#### nilable

If the type is set to nilable this tells puppet-runner that we want to pass in a nil/undef (null) value instead of an empty string, if the fact value is blank '' it will be converted into a tilda (~) as this is the nil representation  in hiera.  If the conversions is successfull the fact reference in the final compiled hiera document (/etc/puppet/hiera/<HOSTNAME>.eyaml) would be replaced with a tilda.  Please note this only works for puppet variables that are defaulted in the code to undef, if they have a value passing nil to them will result in the code default still being set

Example:

Template
```
---
classes:
  - artifactory


artifactory::conf:
    tarball_location_file: "%{::artifactory_file_location}"
    tarball_location_url:  "%{::artifactory_url_location}"
    .........
```

If the defaults does not use metadata (or uses a type of string) and the facts are set as below
```
---
  
artifactory_file_location: '/tmp/file.zip'
artifactory_url_location: 
```

They are therefore both mandatory fileds and puppet-runner will ask for you to give a value for both, however in reality these are mutually exclusive, one will take precident over the other so passing them both could have unforseen consequences.

The other otpion is to set the facts to be empty string, however this still passed an empty string into puppet which, unless the code has been written to discount that, could still cause issues:
```
artifactory_file_location: '/tmp/file.zip'
artifactory_url_location: ''
```

Then the value writen into /etc/puppet/hiera/<HOSTNAME>.eyaml would be 

```
artifactory::conf:
    tarball_location_file: "%{::artifactory_file_location}"
    tarball_location_url:  "%{::artifactory_url_location}"
```

Whereas if the metadata type was set to nilable and a value of '' (empty string is supplied)  in the defaults
```
---
  
artifactory_file_location:
  value: ''
  comment: 'blah'
  type: 'nilable'
artifactory_url_location: 
  value: ''
  comment: 'other blah'
  type: 'nilable'
```

And the facts were set with a value for one and empty string for the other as below:
```
artifactory_file_location: '/tmp/file.zip'
artifactory_url_location: ''
```

Then the value writen into /etc/puppet/hiera/<HOSTNAME>.eyaml would be 

```
artifactory::conf:
    tarball_location_file: "%{::artifactory_file_location}"
    tarball_location_url:  ~
```

### Inter fact references

There are a number of occasions where you may want one fact to point to the value of another, either because you want it to be exactly the same or you want your fact to be a superset of the other, puppet-runner will evaluate facts that reference another fact and present the last fact reference to puppet, the resolution will recursivly resolve facts down to their base fact to a max depth of 5, after which it will stop in order to prevent infinite loops, this will cause a failure of the fact lookup.

#### Example 1: Fact directly referneces another fact

In this example we want our fact to reference another, in this example we will point a custom fact at a system fact (although you can point it at any fact, system or custom)

**template:**
````
---
  
prefixes:
  - vpn_snat_

classes:
  - fw

dependencies:
  - fw
  - firewall
  - stdlib

fw::rules: &fw_rules
  "%{::vpn_snat_description}":
      chain: "%{::vpn_snat_chain}"
      tosource: "%{::vpn_snat_tosource}"
      jump: "%{::vpn_snat_jump}"
      source: "%{::vpn_snat_source}"
      table: "%{::vpn_snat_table}"
      proto: "%{::vpn_snat_proto}"
````

We want the `tosource` value to be set with the IP address for the servers eth0 adapter, there is already a system fact for this `ipaddress_eth0` 

We set the facts as below:

````
vpn_snat_description: '000 VPN SNAT Configuration'
vpn_snat_chain: 'POSTROUTING'
vpn_snat_tosource: "%{::ipaddress_eth0}"
vpn_snat_jump: 'SNAT'
vpn_snat_source: '172.28.254.0/23'
vpn_snat_table: 'nat'
vpn_snat_proto: 'all'
````

Pupet-runner will resolve the `vpn_snat_tosource` faqt down to the first fact it references, which is `ipaddress_eth0`, as a result the value writen into /etc/puppet/hiera/<HOSTNAME>.eyaml would be 

````
fw::rules: &fw_rules
  "%{::vpn_snat_description}":
      chain: "%{::vpn_snat_chain}"
      tosource: "%{::ipaddress_eth0}"
      jump: "%{::vpn_snat_jump}"
      source: "%{::vpn_snat_source}"
      table: "%{::vpn_snat_table}"
      proto: "%{::vpn_snat_proto}"
````

#### Example 2: Fact includes another fact as part of its value

In this example we want our fact to be a superset of another fact.

**template:**
````
---

prefixes:
  - tripwire_

classes:
  - tripwire

dependencies:
  - tripwire
  - stdlib
  - concat

tripwire::local_passphrase: '%{::tripwire_local_passphrase}'
tripwire::site_passphrase: '%{::tripwire_site_passphrase}'
tripwire::tripwire_email: '%{::tripwire_tripwire_email}'
tripwire::tripwire_policy_file: '%{::tripwire_tripwire_policy_file}'
````

We want the `site_passphrase` value to be the same as `local_passphrase` but with _LOCAL at the end

We set the facts as below:

````
tripwire_global_passphrase: 'super_secret'
tripwire_local_passphrase: "%{::tripwire_site_passphrase}_LOCAL"
tripwire_site_passphrase: "%{::tripwire_global_passphrase}
tripwire_tripwire_email: 'blackhole'
tripwire_tripwire_policy_file: 'false'
````
 
Note here we have added a custom fact that is not references in any template or default, this will still be avaliable via facter in the normal way.

The fact `tripwire_site_passphrase` will resolve down to `tripwire_global_passphrase` as in the previous example, however the fact `tripwire_local_passphrase` will be resolved twice (once to `tripwire_site_passphrase` and then again down to `tripwire_global_passphrase`)

As a result the value writen into /etc/puppet/hiera/<HOSTNAME>.eyaml would be 

````
tripwire::local_passphrase: '%{::tripwire_global_passphrase}_LOCAL'
tripwire::site_passphrase: '%{::tripwire_global_passphrase}'
tripwire::tripwire_email: '%{::tripwire_tripwire_email}'
tripwire::tripwire_policy_file: '%{::tripwire_tripwire_policy_file}'
````

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
*  -x CUSTOM_FACTS_DIR --custom_facts_dir CUSTOM_FACTS_DIR                   Directory containing yaml files with custom facts that will be merged with ones from <hostname>_facts.yaml, custom facts can overwrite them 
*  -r PUPPETFILE_CONFIG --puppetfile_config puppetfile_config                Puppetfile composition config file
*  -o PUPPETFILE_OUTPUT_PATH --puppetfile_output_path PUPPETFILE_OUTPUT_PATH Result Puppetfile path
*  -e EYAML_KEY_PATH --eyaml_key_pair EYAML_KEY_PATH                         Path to eyaml encryption key pair
*  -p PUPPET_APPLY --puppet_apply PUPPET_APPLY                               Custom puppet apply command to run
*    -k --keep-facts                                                        Flag to keep the encrypted facts file in /tmp for analysis
*  -n --dry-run                                                              Flag to indicate puppet should run in dry run mode (--noop), this also sets the verbose flag to true
*  -v --verbose                                                              Flag to indicate that all output from puppet apply should be displayed instead of just stdout
Commands:


Commands:

*  all           Runs the following commands prepare, start 
*  start         Runs puppet apply 
*  prepare       Creates result hiera config as a composition of functionalities based on config, merges provided facts with defaults

## License

puppet-runner is released under the terms of the Apache 2.0 license. See LICENSE.txt

## Contributing

1. Fork it ( https://github.com/adaptavist/puppet-runner/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

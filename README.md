# puppet-runner

Executable gem that composes hiera configuration and facts and execute puppet apply 

## Installation

    $ gem install puppet-runner

## Usage

Usage:
  puppet-runner (prepare|start|all) [-c CONFIG_DIR] [-t TEMPLATES] [-d DESTINATION_DIR] [-f FACTS_DEST] [-s SERVERNAME]
  puppet-runner -h | --help

Options:
  -h --help                                       Show this screen.
  -s SERVERNAME --servername SERVERNAME           Custom identification of server, hostname fact if not provided
  -c CONFIG_DIR --config_dir CONFIG_DIR           Hiera configuration directory, must ontain "hostname".yaml and "hostname"_facts.yaml
  -d DESTINATION_DIR --dest_dir DESTINATION_DIR   Directory for result hiera config.
  -t TEMPLATES --templates TEMPLATES              Directory containing templates and defaults folder with functionality templates and default facts
  -f FACTS_DEST --facts_dest_dir FACTS_DEST       Destination directory to store result facts

Commands:
  all           Runs the following commands prepare, start 
  start         Runs puppet apply 
  prepare       Creates result hiera config as a composition of functionalities based on config, merges provided facts with defaults


## Contributing

1. Fork it ( https://github.com/[my-github-username]/puppet-runner/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

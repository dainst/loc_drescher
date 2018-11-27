# Deprecated: https://github.com/dainst/marc_authority_harvester

## Prerequisites 

### Variant: Docker

If you want to run the harvester with docker, there are no further prerequisites.

### Variant: Elixir/Erlang installation

Elixir runs in the Erlang Virtual Machine (VM), so you will need to install both Erlang and Elixir

For further installation information and variants see:

* http://www.erlang.org/downloads
* http://elixir-lang.org/install.html
* https://www.erlang-solutions.com/resources/download.html

After having installed both Erlang and Elixir, check out the repository, switch to its root directory and run 
`mix deps.get`.    

[Mix](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) is Elixir's package manager/build tool 
and should download everything automatically by reading the dependencies from  `mix.exs`.

## Usage

### Running the program

#### (1) Using Docker

* Build the image: `docker build -t dainst/loc_drescher .`.
* Run the script: `docker run -v <Repository Path>/output:/loc_drescher/output dainst/loc_drescher <mix command, see 
(2)>`.

#### (2) Using Mix:
* In the root directory, run `mix run lib/loc_drescher.exs <mode> [options]`.
* This is the easiest way to run the application during development.
 only available `mode` is `update`, which harvests the update feeds provided by the Library of Congress (see 
 [here](http://id.loc.gov/techcenter/)) and produces a single MARC21 output file. Different feeds can be subscribed to 
 by changing the `./config/config.exs` file.

#### Options
* `-t | --target <target path>` for specifying the desired output directory. This is _optional_. Each `mode` 
defines default filenames in `config/config.exs`.
* `-d | --days <n days offset>`. _Required_ for `update`: Only records that were added or changed in between now and 
the last _n_ days will be harvested, specified by the offset.

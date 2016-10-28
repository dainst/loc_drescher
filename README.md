# loc_drescher
Harvesting application for authority records provided by the Library of Congress.

## Prerequisites
Elixir runs in the Erlang Virtual Machine (VM), for both see:
* https://www.erlang-solutions.com/resources/download.html
* http://www.erlang.org/downloads
* http://elixir-lang.org/install.html

After having installed both Erlang and Elixir, check out the repository, switch
to its root directory and run `mix deps.get`.

## Usage

### Running the program

#### (1) Using Mix:
* In the root directory, run `mix run lib/loc_drescher.exs <mode> [options]`.
* This is the easiest way to run the application during development.

#### (2) Compilation using [escript](http://elixir-lang.org/docs/master/mix/Mix.Tasks.Escript.Build.html):
* In the root directory, run `mix escript.build`.
* This compiles the application into a single executable called `loc_drescher`.
* The executable can be started like any command line application:
`./loc_drescher <mode> [options]`.
* Any machine that has the Erlang Virtual Machine installed can run the executable.

At this time, the only available `mode` is `update`, which harvests the update feeds provided by the Library of Congress (see [here](http://id.loc.gov/techcenter/)) and produces a single MARC21 output file. Different feeds can be subscribed to by changing the `./config/config.exs` file.

#### Options
* `-t | --target <target path>` for specifying the desired output directory and file. This is _optional_: Each `mode` defines a default directory in `config/config.exs`.
* `-d | --days <n days offset>`. _Required_ for `update`: Only updates that were added or changed in between now and the last _n_ days will be harvested, specified by the offset.

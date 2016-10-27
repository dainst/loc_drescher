# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :loc_drescher,
  output:
  %{
    default_root: "./output/",
    update:
    [
      { 100, "loc_update_personal_names.mrc" },
      { 110, "loc_update_corporate_names.mrc" },
      { 111, "loc_update_meeting_names.mrc" },
      { 130, "loc_update_uniform_titles.mrc" }
    ],
    import: "loc_import.mrc",
    last_update_info: "./log/last_successful_run.log"
  },
  subscribed_feeds:
  %{
    names: "http://id.loc.gov/authorities/names/feed/",
    subjects: "http://id.loc.gov/authorities/subjects/feed/"
  }

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :loc_drescher, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:loc_drescher, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

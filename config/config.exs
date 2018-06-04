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
    last_update_info: "./log/last_run.log"
  },
  subscribed_feeds:
  %{
    names: "http://id.loc.gov/authorities/names/feed/",
    subjects: "http://id.loc.gov/authorities/subjects/feed/"
  }

# tell logger to load a LoggerFileBackend processes
config :logger,
  backends: [
    { LoggerFileBackend, :info_log },
    { LoggerFileBackend, :error_log },
    :console
  ]

# configuration for the {LoggerFileBackend, :error_log} backend
config :logger, :error_log,
  path: "./log/info.log",
  level: :info

# configuration for the {LoggerFileBackend, :error_log} backend
config :logger, :error_log,
  path: "./log/error.log",
  level: :error

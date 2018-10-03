defmodule Mix.Tasks.RestoreUserDataFromDump do
  use Mix.Task

  @shortdoc "Restore user data from a sql dump"

  @moduledoc """
  Download dump file from an object storage and restore it to the app's database

  no command line options supported
  """

  @doc false
  def run(_) do
    Application.ensure_all_started(:explorer)
    Explorer.UserDataDump.restore_from_dump()
  end
end

defmodule Explorer.UserDataDump do
  @moduledoc """
  Run the process of creating and restoring dumps of user inserted data
  """
  @user_tables [Explorer.Chain.Address.Name, Explorer.Chain.SmartContract]
  @schema_name Application.get_env(:explorer, Explorer.Repo)[:database]
  @network Application.get_env(:explorer, __MODULE__)[:network]
  @bucket Application.get_env(:explorer, __MODULE__)[:dump_bucket]

  @doc """
  Generate a dump of the data on user tables and upload to an object storage
  compatible with the AWS S3 API
  """
  def generate_dump() do
    {dump, 0} = System.cmd("pg_dump", dump_command_args())

    File.write!("user_data_dump.sql", dump)

    "user_data_dump.sql"
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(@bucket, @network <> "/user_data_dump.sql")
    |> ExAws.request()
  after
    File.rm("user_data_dump.sql")
  end

  @doc """
  Retrieve a dump of the data on user tables from an object storage compatible
  with the AWS S3 API and restore it to the current schema
  """
  def restore_from_dump() do
    ExAws.S3.download_file(@bucket, @network <> "/user_data_dump.sql", "user_data_dump.sql") |> ExAws.request!()

    System.cmd("psql", ["-d", @schema_name, "-a", "-f", "user_data_dump.sql"])
  after
    File.rm("user_data_dump.sql")
  end

  defp dump_command_args() do
    Enum.reduce(@user_tables, [@schema_name, "-a"], fn schema, acc ->
      Enum.concat(acc, ["-t", schema.__schema__(:source)])
    end)
  end
end

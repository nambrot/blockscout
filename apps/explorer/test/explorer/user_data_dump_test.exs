defmodule Explorer.UserDataDumpTest do
  use Explorer.DataCase

  alias Plug.Conn

  describe "generate_dump/0" do
    setup do
      bypass = Bypass.open()

      Application.put_env(:ex_aws, :host, "localhost")
      Application.put_env(:ex_aws, :s3, scheme: "http://", host: "localhost", port: bypass.port)

      {:ok, bypass: bypass}
    end

    test "return {:ok, map} when request status is 200", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        conn
        |> Conn.update_resp_header("etag", "etag", fn a -> a || "etag" end)
        |> Conn.resp(200, upload_response_body())
      end)

      assert {:ok, %{}} = Explorer.UserDataDump.generate_dump()
    end

    test "return {:error, etag} when request status is a failure code", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        conn
        |> Conn.update_resp_header("etag", "etag", fn a -> a || "etag" end)
        |> Conn.resp(500, upload_response_body())
      end)

      assert {:error, _} = Explorer.UserDataDump.generate_dump()
    end

    test "delete temporary dump file after a success", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        conn
        |> Conn.update_resp_header("etag", "etag", fn a -> a || "etag" end)
        |> Conn.resp(200, upload_response_body())
      end)

      Explorer.UserDataDump.generate_dump()
      refute File.exists?("./user_data_dump.sql")
    end

    test "delete temporary dump file after an error", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        conn
        |> Conn.update_resp_header("etag", "etag", fn a -> a || "etag" end)
        |> Conn.resp(500, upload_response_body())
      end)

      Explorer.UserDataDump.generate_dump()
      refute File.exists?("./user_data_dump.sql")
    end
  end

  describe "restore_from_dump/0" do
    setup do
      bypass = Bypass.open()

      Application.put_env(:ex_aws, :host, "localhost")
      Application.put_env(:ex_aws, :s3, scheme: "http://", host: "localhost", port: bypass.port)

      {:ok, bypass: bypass}
    end

    test "return {postgres_output, 0} when the restoring works", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        file_size = download_response_body() |> byte_size() |> to_string()

        conn
        |> Conn.update_resp_header("etag", "etag", fn a -> a || "etag" end)
        |> Conn.update_resp_header("Content-Length", file_size, fn a -> a || file_size end)
        |> Conn.resp(200, download_response_body())
      end)

      assert {_, 0} = Explorer.UserDataDump.restore_from_dump()
    end
  end

  defp upload_response_body() do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <InitiateMultipartUploadResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Bucket>somebucket</Bucket>
    <Key>abcd</Key>
    <UploadId>bUCMhxUCGCA0GiTAhTj6cq2rChItfIMYBgO7To9yiuUyDk4CWqhtHPx8cGkgjzyavE2aW6HvhQgu9pvDB3.oX73RC7N3zM9dSU3mecTndVRHQLJCAsySsT6lXRd2Id2a</UploadId>
    <ETag>&quot;89asdfasdf0asdfasdfasd&quot;</ETag>
    </InitiateMultipartUploadResult>
    <CompleteMultipartUploadResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/\">
    <Location>https://google.com</Location>
    <Bucket>name_of_my_bucket</Bucket>
    <Key>name_of_my_key.ext</Key>
    <ETag>&quot;89asdfasdf0asdfasdfasd&quot;</ETag>
    </CompleteMultipartUploadResult>
    <ETag>&quot;89asdfasdf0asdfasdfasd&quot;</ETag>
    """
  end

  defp download_response_body() do
    """
    SET statement_timeout = 0;
    SET lock_timeout = 0;
    SET idle_in_transaction_session_timeout = 0;
    SET client_encoding = 'UTF8';
    SET standard_conforming_strings = on;
    SELECT pg_catalog.set_config('search_path', '', false);
    SET check_function_bodies = false;
    SET client_min_messages = warning;
    SET row_security = off;

    COPY public.address_names (address_hash, name, "primary", inserted_at, updated_at) FROM stdin;
    \\\\xc000e00e00ae00d000d0c00b00000dc0db000000\tixture_address\tf\t2018-12-23 00:00:00.000000\t2018-12-24 00:00:00.000000
    """
  end
end

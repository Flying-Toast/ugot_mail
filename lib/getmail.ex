defmodule Getmail do
  @moduledoc """
  Documentation for `Getmail`.
  """

  @doc """
  ## Options

    * `:server` - Required. Hostname of the IMAP server.

    * `:username` - Required. IMAP username.

    * `:password` - Required. IMAP password.

    * `:port` - Defaults to 993.

    * `:tls` - Whether to use TLS. Defaults to `true`.
  """
  defmacro __using__(init_arg) when is_list(init_arg) do
    for required <- [:server, :username, :password] do
      Keyword.has_key?(init_arg, required) || raise "Missing required argument `:#{required}`."
    end

    init_arg =
      init_arg
      |> Keyword.put_new(:port, 993)
      |> Keyword.put_new(:tls, true)
      |> Keyword.update!(:server, &to_charlist/1)

    quote do
      use GenServer

      def start_link(opts) do
        GenServer.start_link(__MODULE__, unquote(init_arg), opts)
      end

      @impl true
      def init(args) do
        conn = Getmail.IMAP.open(args)

        {:ok, conn}
      end

      @impl true
      def terminate(_reason, conn) do
        Getmail.IMAP.close(conn)
      end

      @impl true
      def handle_info({socket_kind, _socket, data}, conn) when socket_kind in [:ssl, :tcp] do
        conn = Getmail.IMAP.handle_reply(conn, data)

        {:noreply, conn}
      end
    end
  end
end

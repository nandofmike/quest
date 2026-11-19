defmodule ClaperWeb.PtBrCatalogueTest do
  use ExUnit.Case, async: true

  alias Expo.Message.{Plural, Singular}

  @catalogues ~w(default errors)

  test "Português (Brasil) é um idioma disponível" do
    assert "pt_BR" in Gettext.known_locales(ClaperWeb.Gettext)
  end

  test "navegadores configurados em português brasileiro usam pt_BR" do
    conn =
      Plug.Test.conn(:get, "/")
      |> Plug.Conn.put_req_header("accept-language", "pt-BR,pt;q=0.9,en;q=0.8")

    assert hd(ClaperWeb.Plugs.Locale.extract_accept_language(conn)) == "pt_BR"
  end

  for domain <- @catalogues do
    test "todas as mensagens do catálogo #{domain} estão traduzidas" do
      po = Expo.PO.parse_file!("priv/gettext/pt_BR/LC_MESSAGES/#{unquote(domain)}.po")
      assert po.messages != []

      for message <- po.messages do
        refute Expo.Message.has_flag?(message, "fuzzy")

        for translation <- translations(message) do
          refute String.trim(translation) == "",
                 "Tradução vazia para #{IO.iodata_to_binary(message.msgid)}"

          assert placeholders(translation) == placeholders(IO.iodata_to_binary(message.msgid)),
                 "Variáveis divergentes em #{IO.iodata_to_binary(message.msgid)}"
        end
      end
    end
  end

  defp translations(%Singular{msgstr: msgstr}), do: [IO.iodata_to_binary(msgstr)]

  defp translations(%Plural{msgstr: msgstr}) do
    msgstr
    |> Enum.sort_by(fn {index, _} -> index end)
    |> Enum.map(fn {_index, text} -> IO.iodata_to_binary(text) end)
  end

  defp placeholders(text) do
    ~r/%\{[^}]+\}/
    |> Regex.scan(text)
    |> List.flatten()
    |> Enum.sort()
  end
end

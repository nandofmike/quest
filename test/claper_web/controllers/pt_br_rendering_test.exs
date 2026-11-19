defmodule ClaperWeb.PtBrRenderingTest do
  use ClaperWeb.ConnCase, async: true

  test "renders the login page in Brazilian Portuguese when requested", %{conn: conn} do
    html =
      conn
      |> put_req_header("accept-language", "pt-BR,pt;q=0.9,en;q=0.8")
      |> get(~p"/users/log_in")
      |> html_response(200)

    assert html =~ ~s(<html lang="pt-BR")
    assert html =~ "Boas-vindas de volta."
    assert html =~ "Endereço de e-mail"
  end

  test "renders the reset password page in Brazilian Portuguese", %{conn: conn} do
    html =
      conn
      |> put_req_header("accept-language", "pt-BR")
      |> get(~p"/users/reset_password")
      |> html_response(200)

    assert html =~ ~s(<html lang="pt-BR")
    assert html =~ "Voltar ao login"
  end

  test "preserves provider substitutions and confirms a recorded vote in Portuguese" do
    Gettext.with_locale(ClaperWeb.Gettext, "pt_BR", fn ->
      assert Gettext.gettext(ClaperWeb.Gettext, "Log in with %{provider}",
               provider: "ProvedorTeste"
             ) == "Entrar com ProvedorTeste"

      assert Gettext.gettext(ClaperWeb.Gettext, "Voted") == "Voto registrado"
    end)
  end
end

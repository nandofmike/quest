defmodule ClaperWeb.BsbledBrandingTest do
  use ClaperWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup do
    enable_account_creation = Application.get_env(:claper, :enable_account_creation)
    oidc = Application.get_env(:claper, :oidc)

    on_exit(fn ->
      Application.put_env(:claper, :enable_account_creation, enable_account_creation)
      Application.put_env(:claper, :oidc, oidc)
    end)

    Application.put_env(:claper, :enable_account_creation, true)
    Application.put_env(:claper, :oidc, Keyword.put(oidc, :disable_password_login, false))
    :ok
  end

  test "registration page shows the Quest brand without upstream audience claims", %{
    conn: conn
  } do
    html =
      conn
      |> put_req_header("accept-language", "pt-BR")
      |> get(~p"/users/register")
      |> html_response(200)

    assert html =~ " · Quest"
    assert html =~ "Quest · BSB LED"

    assert html =~
             "Engaje a plateia em tempo real com enquetes, perguntas e apresentações interativas."

    assert html =~ ~s(src="/images/logo-light.svg")
    assert html =~ ~s(alt="BSB LED")
    refute html =~ "6.000"
    refute html =~ "6,000"
    refute html =~ "Milhares de apresentadores"
  end

  test "join page links to BSB LED and to local registration, not to claper.co", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")

    assert html =~ "https://bsbled.com.br/"
    assert html =~ ~s(href="/users/register")
    refute html =~ "claper.co"
  end

  test "join page hides the presenter sign-up link when account creation is disabled", %{
    conn: conn
  } do
    Application.put_env(:claper, :enable_account_creation, false)

    {:ok, _view, html} = live(conn, ~p"/")

    refute html =~ ~s(href="/users/register")
  end

  test "logo assets carry the BSB LED identity" do
    for file <- ~w(logo.svg logo-light.svg logo-white.svg logo-large.svg logo-large-black.svg) do
      assert File.read!(Path.join(["priv", "static", "images", file])) =~
               "<title>BSB LED</title>"
    end
  end

  test "email layout credits BSB LED instead of claper.co" do
    layout = File.read!("lib/claper_web/templates/layout/email.html.heex")

    assert layout =~ "&copy; <strong>BSB LED</strong>"
    refute layout =~ "claper.co"
  end

  test "Portuguese messages use the Quest name" do
    Gettext.with_locale(ClaperWeb.Gettext, "pt_BR", fn ->
      assert Gettext.gettext(ClaperWeb.Gettext, "Connect to Quest") == "Conectar-se ao Quest"

      assert Gettext.gettext(ClaperWeb.Gettext, "Confirm your sign-in to Quest") ==
               "Confirme seu acesso ao Quest"
    end)
  end
end

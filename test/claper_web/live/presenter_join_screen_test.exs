defmodule ClaperWeb.PresenterJoinScreenTest do
  use ClaperWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Claper.PresentationsFixtures

  setup :register_and_log_in_user

  test "the join screen scales with the window so it fits any display", %{conn: conn, user: user} do
    presentation_file = presentation_file_fixture(%{user: user}, [:event])
    presentation_state_fixture(%{presentation_file: presentation_file, join_screen_visible: true})

    {:ok, presenter_live, _html} =
      live(conn, ~p"/e/#{presentation_file.event.code}/presenter")

    instructions = presenter_live |> element("#join-instructions") |> render()

    assert instructions =~ "overflow-hidden"
    assert instructions =~ "text-[length:min("
    refute instructions =~ "lg:text-8xl"
    refute instructions =~ "mb-14"
    assert has_element?(presenter_live, ~s(#qr[data-dynamic="true"]))
  end
end

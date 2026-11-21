defmodule ClaperWeb.ModerateLiveTest do
  use ClaperWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Claper.{AccountsFixtures, PostsFixtures, PresentationsFixtures}

  alias Claper.Posts
  alias Claper.Presentations.PresentationState

  defp create_event(%{user: user}) do
    presentation_file = presentation_file_fixture(%{user: user}, [:event])
    state = presentation_state_fixture(%{presentation_file: presentation_file})

    %{event: presentation_file.event, state: Claper.Repo.get!(PresentationState, state.id)}
  end

  defp question(event, body), do: post_fixture(%{event: event, user: user_fixture(), body: body})

  defp tab(view, name), do: view |> element(~s(button[phx-value-tab="#{name}"])) |> render()

  defp open_tab(view, name),
    do: view |> element(~s(button[phx-value-tab="#{name}"])) |> render_click()

  defp act(view, post, status) do
    view
    |> element(
      ~s(button[phx-click="set-status"][phx-value-id="#{post.uuid}"][phx-value-status="#{status}"])
    )
    |> render_click()
  end

  describe "moderation status" do
    test "questions start as new and only accept known statuses" do
      post = question(Claper.EventsFixtures.event_fixture(), "Pergunta?")

      assert post.moderation_status == "new"
      assert {:ok, selected} = Posts.set_moderation_status(post, "selected")
      assert selected.moderation_status == "selected"
      assert selected.moderated_at
      assert {:error, :invalid_status} = Posts.set_moderation_status(post, "published")
    end

    test "attendees cannot set the moderation status when posting" do
      event = Claper.EventsFixtures.event_fixture()

      {:ok, post} =
        Posts.create_post(event, %{
          body: "Forjada",
          uuid: Ecto.UUID.generate(),
          attendee_identifier: "x",
          moderation_status: "selected"
        })

      assert post.moderation_status == "new"
    end
  end

  describe "access" do
    setup [:register_and_log_in_user, :create_event]

    test "the event owner opens the moderator screen", %{conn: conn, event: event} do
      {:ok, _view, html} = live(conn, ~p"/e/#{event.code}/moderar")

      assert html =~ event.name
      assert html =~ "New"
    end

    test "a facilitator opens the moderator screen", %{event: event} do
      facilitator = user_fixture()

      {:ok, _} =
        Claper.Events.create_activity_leader(%{event_id: event.id, email: facilitator.email})

      conn = build_conn() |> log_in_user(facilitator)
      assert {:ok, _view, _html} = live(conn, ~p"/e/#{event.code}/moderar")
    end

    test "someone outside the event team is sent away", %{event: event} do
      conn = build_conn() |> log_in_user(user_fixture())

      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/e/#{event.code}/moderar")
    end

    test "a visitor without an account is asked to log in", %{event: event} do
      assert {:error, {:redirect, %{to: "/users/log_in"}}} =
               live(build_conn(), ~p"/e/#{event.code}/moderar")
    end

    test "the manager links to the moderator screen", %{conn: conn, event: event} do
      {:ok, manage_live, _html} = live(conn, ~p"/e/#{event.code}/manage")

      assert has_element?(manage_live, ~s(a[href="/e/#{event.code}/moderar"]))
    end
  end

  describe "moderating questions" do
    setup [:register_and_log_in_user, :create_event]

    test "every question arrives as new, with or without a question mark", %{
      conn: conn,
      event: event
    } do
      question(event, "Sem interrogacao")
      {:ok, view, _html} = live(conn, ~p"/e/#{event.code}/moderar")

      question(event, "Chegou agora?")

      html = render(view)
      assert html =~ "Sem interrogacao"
      assert html =~ "Chegou agora?"
      assert tab(view, "new") =~ "(2)"
    end

    test "selecting, reading and discarding move questions between tabs", %{
      conn: conn,
      event: event
    } do
      first = question(event, "Primeira?")
      second = question(event, "Segunda?")
      third = question(event, "Terceira?")
      {:ok, view, _html} = live(conn, ~p"/e/#{event.code}/moderar")

      act(view, first, "selected")
      act(view, second, "read")
      act(view, third, "discarded")

      assert tab(view, "new") =~ "(0)"
      assert tab(view, "selected") =~ "(1)"
      assert tab(view, "read") =~ "(1)"
      assert tab(view, "discarded") =~ "(1)"

      open_tab(view, "selected")
      assert render(view) =~ "Primeira?"
      refute render(view) =~ "Terceira?"
    end

    test "a discarded question is kept, not deleted, and can be undone", %{
      conn: conn,
      event: event
    } do
      post = question(event, "Descartar?")
      {:ok, view, _html} = live(conn, ~p"/e/#{event.code}/moderar")

      act(view, post, "discarded")
      assert Posts.get_post!(post.uuid).moderation_status == "discarded"

      view |> element(~s(button[phx-click="undo"])) |> render_click()

      assert Posts.get_post!(post.uuid).moderation_status == "new"
      assert tab(view, "new") =~ "(1)"
    end

    test "two moderators stay in sync", %{conn: conn, event: event} do
      post = question(event, "Sincronizada?")
      {:ok, first_view, _html} = live(conn, ~p"/e/#{event.code}/moderar")
      {:ok, second_view, _html} = live(conn, ~p"/e/#{event.code}/moderar")

      act(first_view, post, "selected")

      assert tab(second_view, "selected") =~ "(1)"
      assert tab(second_view, "new") =~ "(0)"
    end

    test "questions from another event cannot be moderated here", %{conn: conn, event: event} do
      other = question(Claper.EventsFixtures.event_fixture(), "Outro evento?")
      {:ok, view, _html} = live(conn, ~p"/e/#{event.code}/moderar")

      render_hook(view, "set-status", %{"id" => other.uuid, "status" => "discarded"})

      assert Posts.get_post!(other.uuid).moderation_status == "new"
    end

    test "the moderator can close and reopen questions", %{
      conn: conn,
      event: event,
      state: state
    } do
      {:ok, view, _html} = live(conn, ~p"/e/#{event.code}/moderar")

      view |> element("#toggle-questions") |> render_click()
      refute Claper.Repo.get!(PresentationState, state.id).chat_enabled

      view |> element("#toggle-questions") |> render_click()
      assert Claper.Repo.get!(PresentationState, state.id).chat_enabled
    end

    test "closing questions asks for confirmation", %{conn: conn, event: event} do
      {:ok, view, _html} = live(conn, ~p"/e/#{event.code}/moderar")

      assert has_element?(view, "#toggle-questions[data-confirm]")
    end

    test "question text is shown as text, never as markup", %{conn: conn, event: event} do
      question(event, "<script>alert(1)</script>?")
      {:ok, _view, html} = live(conn, ~p"/e/#{event.code}/moderar")

      refute html =~ "<script>alert(1)</script>"
    end

    test "the screen leaves when the event is terminated", %{conn: conn, event: event} do
      {:ok, view, _html} = live(conn, ~p"/e/#{event.code}/moderar")

      {:ok, _} = Claper.Events.terminate_event(event)

      assert_redirect(view, ~p"/events")
    end
  end

  describe "review follow-ups" do
    setup [:register_and_log_in_user, :create_event]

    test "triage goes to the moderation topic only and never reverts a pin", %{
      conn: conn,
      event: event
    } do
      post = question(event, "Fixada?")
      {:ok, view, _html} = live(conn, ~p"/e/#{event.code}/moderar")
      {:ok, _} = Posts.toggle_pin_post(Posts.get_post!(post.uuid, [:event]))

      Claper.Events.Event.subscribe(event.uuid)
      Posts.subscribe_moderation(event.uuid)
      act(view, post, "selected")

      assert_receive {:post_moderated, %{pinned: true, moderation_status: "selected"}}
      refute_receive {:post_updated, _}, 100
      assert Posts.get_post!(post.uuid).pinned
    end

    test "a double tap keeps undo working", %{conn: conn, event: event} do
      post = question(event, "Toque duplo?")
      {:ok, view, _html} = live(conn, ~p"/e/#{event.code}/moderar")

      render_hook(view, "set-status", %{"id" => post.uuid, "status" => "discarded"})
      render_hook(view, "set-status", %{"id" => post.uuid, "status" => "discarded"})
      view |> element(~s(button[phx-click="undo"])) |> render_click()

      assert Posts.get_post!(post.uuid).moderation_status == "new"
    end

    test "undo does not override another moderator", %{conn: conn, event: event} do
      post = question(event, "Disputada?")
      {:ok, view, _html} = live(conn, ~p"/e/#{event.code}/moderar")

      act(view, post, "discarded")
      {:ok, _} = Posts.set_moderation_status(Posts.get_post!(post.uuid), "selected")
      view |> element(~s(button[phx-click="undo"])) |> render_click()

      assert Posts.get_post!(post.uuid).moderation_status == "selected"
      assert render(view) =~ "Another moderator already changed this question."
    end

    test "a question deleted elsewhere leaves the list without breaking the screen", %{
      conn: conn,
      event: event
    } do
      post = question(event, "Apagada?")
      {:ok, view, _html} = live(conn, ~p"/e/#{event.code}/moderar")

      {:ok, _} = Posts.delete_post(Posts.get_post!(post.uuid, [:event]))
      refute render(view) =~ "Apagada?"

      render_hook(view, "set-status", %{"id" => post.uuid, "status" => "selected"})
      assert render(view) =~ event.name
    end

    test "a facilitator removed from the event loses moderation power", %{event: event} do
      facilitator = user_fixture()

      {:ok, _} =
        Claper.Events.create_activity_leader(%{event_id: event.id, email: facilitator.email})

      post = question(event, "Depois da remocao?")
      conn = build_conn() |> log_in_user(facilitator)
      {:ok, view, _html} = live(conn, ~p"/e/#{event.code}/moderar")

      Claper.Repo.delete_all(Claper.Events.ActivityLeader)

      render_hook(view, "set-status", %{"id" => post.uuid, "status" => "discarded"})

      assert Posts.get_post!(post.uuid).moderation_status == "new"
      assert_redirect(view, ~p"/")
    end

    test "a question received twice is listed once", %{conn: conn, event: event} do
      post = question(event, "Repetida?")
      {:ok, view, _html} = live(conn, ~p"/e/#{event.code}/moderar")

      send(view.pid, {:post_created, Posts.get_post!(post.uuid)})

      assert tab(view, "new") =~ "(1)"
    end

    test "attendees cannot forge a moderation status when sending a question", %{
      event: event,
      state: state
    } do
      {:ok, _} = Claper.Presentations.update_presentation_state(state, %{chat_enabled: true})

      {:ok, post} =
        Posts.create_attendee_post(event, {:attendee, "plateia-1", nil}, %{
          "body" => "Forjada?",
          "moderation_status" => "selected"
        })

      assert post.moderation_status == "new"
    end

    test "new questions keep arrival order and selected ones keep selection order", %{
      conn: conn,
      event: event
    } do
      first = question(event, "Primeira a chegar?")
      second = question(event, "Segunda a chegar?")
      {:ok, view, _html} = live(conn, ~p"/e/#{event.code}/moderar")

      html = render(view)
      assert :binary.match(html, "Primeira a chegar?") < :binary.match(html, "Segunda a chegar?")

      act(view, second, "selected")
      act(view, first, "selected")
      open_tab(view, "selected")

      html = render(view)
      assert :binary.match(html, "Segunda a chegar?") < :binary.match(html, "Primeira a chegar?")
    end

    test "the open list survives a reconnection", %{conn: conn, event: event} do
      {:ok, view, _html} = live(conn, ~p"/e/#{event.code}/moderar")

      open_tab(view, "selected")
      assert_patch(view, ~p"/e/#{event.code}/moderar?tab=selected")

      {:ok, view, _html} = live(conn, ~p"/e/#{event.code}/moderar?tab=selected")
      assert tab(view, "selected") =~ ~s(aria-pressed="true")
    end

    test "closing questions twice keeps them closed", %{conn: conn, event: event, state: state} do
      {:ok, view, _html} = live(conn, ~p"/e/#{event.code}/moderar")

      render_hook(view, "set-questions", %{"enabled" => "false"})
      render_hook(view, "set-questions", %{"enabled" => "false"})

      refute Claper.Repo.get!(PresentationState, state.id).chat_enabled
    end

    test "outside debate mode the screen warns that discarding does not hide questions", %{
      conn: conn,
      event: event
    } do
      {:ok, _view, html} = live(conn, ~p"/e/#{event.code}/moderar")

      assert html =~ "Debate mode is off"
    end
  end

  describe "report" do
    setup [:register_and_log_in_user, :create_event]

    test "the messages export includes the moderation status", %{conn: conn, event: event} do
      post = question(event, "No relatorio?")
      {:ok, _} = Posts.set_moderation_status(post, "read")

      csv = conn |> post(~p"/export/#{event.uuid}/messages") |> response(200)

      assert csv =~ "Moderation status"
      assert csv =~ "read"
    end
  end
end

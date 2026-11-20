defmodule ClaperWeb.DebateModeTest do
  use ClaperWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Claper.{AccountsFixtures, PostsFixtures, PresentationsFixtures}

  alias Claper.Presentations

  defp create_event(%{user: user}) do
    presentation_file = presentation_file_fixture(%{user: user}, [:event])
    state = presentation_state_fixture(%{presentation_file: presentation_file})

    %{presentation_file: presentation_file, event: presentation_file.event, state: state}
  end

  defp enable_debate_mode(state) do
    # Reload so the broadcast carries the database defaults, as in the running app.
    state = Claper.Repo.get!(Claper.Presentations.PresentationState, state.id)
    {:ok, state} = Presentations.update_presentation_state(state, %{debate_mode: true})
    state
  end

  describe "attendee room in debate mode" do
    setup [:register_and_log_in_user, :create_event]

    test "a participant sees only their own questions", %{event: event, state: state} do
      enable_debate_mode(state)
      participant = user_fixture()
      other = user_fixture()

      post_fixture(%{event: event, user: other, body: "Pergunta de outra pessoa?"})
      post_fixture(%{event: event, user: participant, body: "Minha pergunta?"})

      conn = build_conn() |> log_in_user(participant)
      {:ok, show_live, html} = live(conn, ~p"/e/#{event.code}")

      assert html =~ "Minha pergunta?"
      refute html =~ "Pergunta de outra pessoa?"

      post_fixture(%{event: event, user: other, body: "Chegou agora?"})
      refute render(show_live) =~ "Chegou agora?"

      post_fixture(%{event: event, user: participant, body: "Minha segunda?"})
      assert render(show_live) =~ "Minha segunda?"
    end

    test "turning debate mode on hides questions already on screen", %{event: event, state: state} do
      participant = user_fixture()
      post_fixture(%{event: event, user: user_fixture(), body: "Visivel antes?"})

      conn = build_conn() |> log_in_user(participant)
      {:ok, show_live, html} = live(conn, ~p"/e/#{event.code}")
      assert html =~ "Visivel antes?"

      enable_debate_mode(state)
      refute render(show_live) =~ "Visivel antes?"
    end

    test "participants get no slides and no reactions in debate mode", %{
      event: event,
      state: state
    } do
      enable_debate_mode(state)
      participant = user_fixture()
      post_fixture(%{event: event, user: participant, body: "Minha pergunta?"})

      conn = build_conn() |> log_in_user(participant)
      {:ok, show_live, _html} = live(conn, ~p"/e/#{event.code}")

      refute has_element?(show_live, "#focus-media")
      refute has_element?(show_live, ~s([aria-label="React to message"]))
    end

    test "a sent question is confirmed to the participant", %{event: event, state: state} do
      enable_debate_mode(state)
      conn = build_conn() |> log_in_user(user_fixture())
      {:ok, show_live, _html} = live(conn, ~p"/e/#{event.code}")

      show_live
      |> form("#post-form", post: %{body: "Qual o plano?"})
      |> render_submit()

      assert render(show_live) =~ "Question sent. Only the moderators will see it."
    end
  end

  describe "presenter screen in debate mode" do
    setup [:register_and_log_in_user, :create_event]

    test "questions never reach the screen, even with messages shown", %{
      conn: conn,
      event: event,
      state: state
    } do
      {:ok, state} = Presentations.update_presentation_state(state, %{chat_visible: true})
      enable_debate_mode(state)
      post_fixture(%{event: event, user: user_fixture(), body: "Nao pode ir ao telao?"})

      {:ok, presenter_live, html} = live(conn, ~p"/e/#{event.code}/presenter")

      refute html =~ "Nao pode ir ao telao?"
      post_fixture(%{event: event, user: user_fixture(), body: "Nem esta?"})
      refute render(presenter_live) =~ "Nem esta?"
    end
  end

  describe "manager in debate mode" do
    setup [:register_and_log_in_user, :create_event]

    test "every message counts as a question", %{conn: conn, event: event, state: state} do
      enable_debate_mode(state)
      post_fixture(%{event: event, user: user_fixture(), body: "Sem interrogacao"})
      post_fixture(%{event: event, user: user_fixture(), body: "Com interrogacao?"})

      {:ok, manage_live, _html} = live(conn, ~p"/e/#{event.code}/manage")

      manage_live
      |> element(~s(button[phx-click="list-tab"][phx-value-tab="questions"]))
      |> render_click()

      html = render(manage_live)
      assert html =~ "Sem interrogacao"
      assert html =~ "Com interrogacao?"
    end

    test "debate mode can be switched on from the manager", %{
      conn: conn,
      event: event,
      state: state
    } do
      {:ok, manage_live, _html} = live(conn, ~p"/e/#{event.code}/manage")

      render_hook(manage_live, "checked", %{"key" => "debate_mode", "value" => true})

      assert Claper.Repo.get!(Claper.Presentations.PresentationState, state.id).debate_mode
    end
  end

  describe "live event safety" do
    setup [:register_and_log_in_user, :create_event]

    test "manager toggles declare shortcuts without window key bindings", %{
      conn: conn,
      event: event
    } do
      {:ok, _manage_live, html} = live(conn, ~p"/e/#{event.code}/manage")

      assert html =~ ~s(data-shortcut="Q")
      assert html =~ ~s(data-shortcut="A")
      refute html =~ ~s(phx-key="Q")
      refute html =~ ~s(phx-key="A")
    end

    test "deleting a message from the manager asks for confirmation", %{
      conn: conn,
      event: event
    } do
      post_fixture(%{event: event, user: user_fixture(), body: "Apagar?"})
      {:ok, manage_live, _html} = live(conn, ~p"/e/#{event.code}/manage")

      assert has_element?(manage_live, ~s(button[phx-click="delete"][data-confirm]))
    end

    test "the open presentation button is not hidden on tablets", %{conn: conn, event: event} do
      {:ok, manage_live, _html} = live(conn, ~p"/e/#{event.code}/manage")

      button = manage_live |> element("#openPresenter-#{event.uuid}") |> render()
      refute button =~ ~r/<button[^>]*class="hidden/
    end

    test "terminating the event tells the presenter screen and the manager", %{
      conn: conn,
      event: event
    } do
      {:ok, presenter_live, _html} = live(conn, ~p"/e/#{event.code}/presenter")
      {:ok, manage_live, _html} = live(conn, ~p"/e/#{event.code}/manage")

      {:ok, _} = Claper.Events.terminate_event(event)

      assert render(presenter_live) =~ "This event has been terminated"
      assert_redirect(manage_live, ~p"/events")
    end

    test "deleting the event sends connected participants away", %{event: event} do
      conn = build_conn() |> log_in_user(user_fixture())
      {:ok, show_live, _html} = live(conn, ~p"/e/#{event.code}")

      {:ok, _} = Claper.Events.delete_event(event)

      assert_redirect(show_live, ~p"/")
    end
  end

  describe "presentation removal" do
    setup [:register_and_log_in_user, :create_event]

    test "removing the presentation detaches its slides", %{presentation_file: presentation_file} do
      {:ok, removed} = Presentations.remove_presentation(presentation_file)

      assert removed.hash == nil
      assert removed.length == 0
      assert Presentations.get_slide_urls(removed) == []
    end

    test "the owner can remove the presentation from the event form", %{
      conn: conn,
      event: event,
      presentation_file: presentation_file
    } do
      {:ok, edit_live, _html} = live(conn, ~p"/events/#{event.uuid}/edit")

      edit_live |> element("#remove-presentation") |> render_click()

      removed = Claper.Repo.get!(Claper.Presentations.PresentationFile, presentation_file.id)
      assert removed.length == 0
      refute has_element?(edit_live, "#remove-presentation")
    end
  end

  describe "public pages" do
    test "the home page carries a small source code link", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ ~s(href="/codigo-fonte/")
    end
  end

  describe "review follow-ups" do
    setup [:register_and_log_in_user, :create_event]

    defp questions_tab(view) do
      view |> element(~s(button[phx-click="list-tab"][phx-value-tab="questions"])) |> render()
    end

    test "a manager opened during the debate counts questions without a question mark", %{
      conn: conn,
      event: event,
      state: state
    } do
      enable_debate_mode(state)
      post_fixture(%{event: event, user: user_fixture(), body: "Sem interrogacao"})

      {:ok, manage_live, _html} = live(conn, ~p"/e/#{event.code}/manage")

      assert questions_tab(manage_live) =~ "(1)"
    end

    test "switching debate mode off goes back to question marks only", %{
      conn: conn,
      event: event,
      state: state
    } do
      enable_debate_mode(state)
      post_fixture(%{event: event, user: user_fixture(), body: "Sem interrogacao"})
      {:ok, manage_live, _html} = live(conn, ~p"/e/#{event.code}/manage")

      render_hook(manage_live, "checked", %{"key" => "debate_mode", "value" => false})

      assert questions_tab(manage_live) =~ "(0)"
    end

    test "another manager follows when debate mode changes", %{
      conn: conn,
      event: event,
      state: state
    } do
      post_fixture(%{event: event, user: user_fixture(), body: "Sem interrogacao"})
      {:ok, manage_live, _html} = live(conn, ~p"/e/#{event.code}/manage")
      assert questions_tab(manage_live) =~ "(0)"

      enable_debate_mode(state)

      assert questions_tab(manage_live) =~ "(1)"
    end

    test "switching debate mode off asks for confirmation and keeps messages off the screen", %{
      conn: conn,
      event: event,
      state: state
    } do
      {:ok, state} = Presentations.update_presentation_state(state, %{chat_visible: true})
      enable_debate_mode(state)
      {:ok, manage_live, _html} = live(conn, ~p"/e/#{event.code}/manage")

      assert has_element?(manage_live, ~s(button[phx-value-key="debate_mode"][data-confirm]))

      render_hook(manage_live, "checked", %{"key" => "debate_mode", "value" => false})

      refute Claper.Repo.get!(Claper.Presentations.PresentationState, state.id).chat_visible
    end

    test "participants cannot send reactions in debate mode", %{event: event, state: state} do
      enable_debate_mode(state)
      conn = build_conn() |> log_in_user(user_fixture())
      {:ok, show_live, _html} = live(conn, ~p"/e/#{event.code}")

      refute has_element?(show_live, "#room-reaction-fab")

      Claper.Events.subscribe_event(event.uuid)
      render_hook(show_live, "global-react", %{"type" => "heart"})
      refute_receive {:react, _}, 200
    end

    test "an anonymous participant sees their own question and nobody else's", %{
      event: event,
      state: state
    } do
      enable_debate_mode(state)
      post_fixture(%{event: event, user: user_fixture(), body: "Pergunta alheia?"})

      {:ok, show_live, html} = live(build_conn(), ~p"/e/#{event.code}")
      refute html =~ "Pergunta alheia?"

      show_live
      |> form("#post-form", post: %{body: "Minha pergunta anonima?"})
      |> render_submit()

      assert render(show_live) =~ "Minha pergunta anonima?"
      refute render(show_live) =~ "Pergunta alheia?"
    end

    test "the event team still sees every question and the slides", %{
      conn: conn,
      event: event,
      state: state
    } do
      enable_debate_mode(state)
      post_fixture(%{event: event, user: user_fixture(), body: "Pergunta da plateia?"})

      {:ok, show_live, html} = live(conn, ~p"/e/#{event.code}")

      assert html =~ "Pergunta da plateia?"
      assert has_element?(show_live, "#focus-media")
    end

    test "the presenter screen shows messages when debate mode is off", %{
      conn: conn,
      event: event,
      state: state
    } do
      {:ok, _} = Presentations.update_presentation_state(state, %{chat_visible: true})
      post_fixture(%{event: event, user: user_fixture(), body: "Aparece no telao?"})

      {:ok, _presenter_live, html} = live(conn, ~p"/e/#{event.code}/presenter")

      assert html =~ "Aparece no telao?"
    end

    test "removing the presentation resets the slide position and tells connected screens", %{
      presentation_file: presentation_file,
      state: state
    } do
      {:ok, _} = Presentations.update_presentation_state(state, %{position: 3})
      Presentations.subscribe(presentation_file.id)

      {:ok, _} = Presentations.remove_presentation(presentation_file)

      assert_receive {:presentation_removed, _}
      assert Claper.Repo.get!(Claper.Presentations.PresentationState, state.id).position == 0
    end

    test "connected participants drop the removed slides", %{
      event: event,
      presentation_file: presentation_file
    } do
      conn = build_conn() |> log_in_user(user_fixture())
      {:ok, show_live, _html} = live(conn, ~p"/e/#{event.code}")
      assert has_element?(show_live, "#focus-media")

      {:ok, _} = Presentations.remove_presentation(presentation_file)

      refute has_element?(show_live, "#focus-media")
    end

    test "presentations shared by a duplicated event keep their files", %{
      presentation_file: presentation_file
    } do
      twin = presentation_file_fixture(%{hash: presentation_file.hash})

      {:ok, _} = Presentations.remove_presentation(presentation_file)

      assert Presentations.get_presentation_files_by_hash(twin.hash) |> Enum.map(& &1.id) ==
               [twin.id]
    end
  end
end

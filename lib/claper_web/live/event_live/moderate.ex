defmodule ClaperWeb.EventLive.Moderate do
  @moduledoc """
  Moderator screen for live Q&A (debate mode): the event team triages audience
  questions into new, selected, read and discarded, on any device.

  Triage changes travel on a moderation-only topic, so attendee screens never
  hear about them. Status changes are compare-and-set, so two moderators acting
  on the same question cannot silently overwrite each other.
  """
  use ClaperWeb, :live_view

  alias Claper.{Events, Posts, Presentations}

  @tabs ~w(new selected read discarded)
  @undo_timeout 8_000

  @impl true
  def mount(%{"code" => code}, session, socket) do
    with %{"locale" => locale} <- session do
      Gettext.put_locale(ClaperWeb.Gettext, locale)
    end

    event =
      Events.get_event_with_code(code, [:user, presentation_file: :presentation_state])

    if is_nil(event) || not leader?(socket, event) do
      {:ok,
       socket
       |> put_flash(:error, gettext("Event doesn't exist"))
       |> redirect(to: "/")}
    else
      if connected?(socket) do
        Claper.Events.Event.subscribe(event.uuid)
        Posts.subscribe_moderation(event.uuid)
        Presentations.subscribe(event.presentation_file.id)
      end

      {:ok,
       socket
       |> assign(:page_title, gettext("Moderate questions"))
       |> assign(:event, event)
       |> assign(:state, event.presentation_file.presentation_state)
       |> assign(:tab, "new")
       |> assign(:last_action, nil)
       |> assign(:posts, Posts.list_posts_for_moderation(event.uuid))
       |> refresh_view()}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    tab = if params["tab"] in @tabs, do: params["tab"], else: "new"
    {:noreply, socket |> assign(:tab, tab) |> refresh_view()}
  end

  defp leader?(%{assigns: %{current_user: current_user}}, event) do
    Events.led_by?(current_user.email, event) || event.user.id == current_user.id
  end

  defp leader?(_socket, _event), do: false

  # Mount checks access once; every change re-checks it, so a facilitator
  # removed during the event loses power even with the screen still open.
  defp authorized?(%{assigns: %{event: event, current_user: user}}),
    do: event.user_id == user.id or Events.led_by?(user.email, event)

  defp authorized?(_socket), do: false

  defp leave(socket) do
    {:noreply,
     socket
     |> put_flash(:error, gettext("You no longer have access to this event"))
     |> push_navigate(to: ~p"/")}
  end

  @impl true
  def handle_event("tab", %{"tab" => tab}, socket) when tab in @tabs do
    {:noreply, push_patch(socket, to: ~p"/e/#{socket.assigns.event.code}/moderar?tab=#{tab}")}
  end

  def handle_event("set-status", %{"id" => uuid, "status" => status}, socket)
      when status in @tabs do
    cond do
      not authorized?(socket) ->
        leave(socket)

      true ->
        case find_post(socket, uuid) do
          nil ->
            {:noreply, socket}

          # A second tap on the same button changes nothing and keeps undo intact.
          %{moderation_status: ^status} ->
            {:noreply, socket}

          post ->
            case Posts.set_moderation_status(post, status, from: post.moderation_status) do
              {:ok, updated} ->
                {:noreply,
                 socket
                 |> upsert_post(updated)
                 |> remember_undo(post, status)
                 |> refresh_view()}

              {:error, :stale} ->
                {:noreply, socket |> reload_post(uuid) |> warn_changed()}

              {:error, _reason} ->
                {:noreply, put_flash(socket, :error, gettext("Could not update the question"))}
            end
        end
    end
  end

  def handle_event("undo", _params, %{assigns: %{last_action: %{} = last}} = socket) do
    if authorized?(socket) do
      socket = assign(socket, :last_action, nil)

      case find_post(socket, last.id) do
        nil ->
          {:noreply, refresh_view(socket)}

        post ->
          case Posts.set_moderation_status(post, last.previous, from: last.status) do
            {:ok, updated} ->
              {:noreply, socket |> upsert_post(updated) |> refresh_view()}

            {:error, _reason} ->
              {:noreply, socket |> reload_post(last.id) |> warn_changed()}
          end
      end
    else
      leave(socket)
    end
  end

  def handle_event("set-questions", %{"enabled" => enabled}, %{assigns: %{state: state}} = socket)
      when enabled in ["true", "false"] do
    if authorized?(socket) do
      case Presentations.update_presentation_state(state, %{chat_enabled: enabled == "true"}) do
        {:ok, state} ->
          {:noreply, assign(socket, :state, state)}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Could not update the question"))}
      end
    else
      leave(socket)
    end
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:post_created, %{event_id: event_id} = post}, socket) do
    if event_id == socket.assigns.event.id do
      {:noreply, socket |> upsert_post(post) |> refresh_view()}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:post_moderated, post}, socket),
    do: {:noreply, socket |> replace_post(post) |> refresh_view()}

  def handle_info({:post_deleted, post}, socket) do
    {:noreply,
     socket
     |> update(:posts, &Enum.reject(&1, fn p -> p.id == post.id end))
     |> refresh_view()}
  end

  def handle_info({:state_updated, state}, socket), do: {:noreply, assign(socket, :state, state)}

  def handle_info({:clear_undo, ref}, %{assigns: %{last_action: %{ref: ref}}} = socket),
    do: {:noreply, assign(socket, :last_action, nil)}

  def handle_info({event_end, _event_uuid}, socket)
      when event_end in [:event_terminated, :event_deleted] do
    {:noreply,
     socket
     |> put_flash(:info, gettext("This event has been terminated"))
     |> push_navigate(to: ~p"/events")}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp find_post(socket, uuid), do: Enum.find(socket.assigns.posts, &(&1.uuid == uuid))

  defp upsert_post(socket, %{id: id} = post) do
    update(socket, :posts, fn posts ->
      if Enum.any?(posts, &(&1.id == id)),
        do: Enum.map(posts, fn existing -> if existing.id == id, do: post, else: existing end),
        else: posts ++ [post]
    end)
  end

  defp replace_post(socket, %{id: id} = post) do
    update(socket, :posts, fn posts ->
      Enum.map(posts, fn existing -> if existing.id == id, do: post, else: existing end)
    end)
  end

  defp reload_post(socket, uuid) do
    socket =
      case Posts.get_moderation_post(socket.assigns.event.id, uuid) do
        nil -> update(socket, :posts, &Enum.reject(&1, fn p -> p.uuid == uuid end))
        post -> upsert_post(socket, post)
      end

    socket |> assign(:last_action, nil) |> refresh_view()
  end

  defp warn_changed(socket),
    do: put_flash(socket, :error, gettext("Another moderator already changed this question."))

  defp remember_undo(socket, post, status) when status in ["read", "discarded"] do
    ref = make_ref()
    Process.send_after(self(), {:clear_undo, ref}, @undo_timeout)

    assign(socket, :last_action, %{
      id: post.uuid,
      previous: post.moderation_status,
      status: status,
      ref: ref
    })
  end

  defp remember_undo(socket, _post, _status), do: assign(socket, :last_action, nil)

  # Counts and the visible list are computed once per change, not on every render.
  defp refresh_view(socket) do
    posts = socket.assigns.posts

    socket
    |> assign(:counts, Enum.frequencies_by(posts, & &1.moderation_status))
    |> assign(:visible_posts, posts_for(posts, socket.assigns.tab))
  end

  @doc false
  def posts_for(posts, "new"),
    do: posts |> Enum.filter(&(&1.moderation_status == "new")) |> Enum.sort_by(& &1.id)

  def posts_for(posts, "selected"),
    do:
      posts
      |> Enum.filter(&(&1.moderation_status == "selected"))
      |> Enum.sort_by(&{moderated_key(&1), &1.id})

  def posts_for(posts, status),
    do:
      posts
      |> Enum.filter(&(&1.moderation_status == status))
      |> Enum.sort_by(&{moderated_key(&1), &1.id}, :desc)

  # ISO 8601 with microseconds sorts chronologically as text, across months too.
  defp moderated_key(%{moderated_at: nil}), do: ""
  defp moderated_key(%{moderated_at: at}), do: NaiveDateTime.to_iso8601(at)

  @doc false
  def tab_label("new"), do: gettext("New")
  def tab_label("selected"), do: gettext("Selected")
  def tab_label("read"), do: gettext("Read")
  def tab_label("discarded"), do: gettext("Discarded")

  @doc false
  def empty_label("new"), do: gettext("New questions from the audience will appear here.")
  def empty_label("selected"), do: gettext("Select the questions you want to read on stage.")
  def empty_label("read"), do: gettext("Questions read on stage will appear here.")
  def empty_label("discarded"), do: gettext("Discarded questions will appear here.")

  @doc false
  def undo_label("read"), do: gettext("Question marked as read.")
  def undo_label("discarded"), do: gettext("Question discarded.")

  @doc false
  def tabs, do: @tabs

  @select "bg-primary-500 text-white hover:bg-primary-600"
  @read "bg-green-600 text-white hover:bg-green-700"
  @neutral "bg-gray-100 text-gray-800 hover:bg-gray-200"
  @discard "border border-red-200 bg-white text-red-700 hover:bg-red-50"

  @doc false
  def actions_for("new"),
    do: [
      {"selected", gettext("Select"), @select},
      {"read", gettext("Mark as read"), @read},
      {"discarded", gettext("Discard"), @discard}
    ]

  def actions_for("selected"),
    do: [
      {"read", gettext("Mark as read"), @read},
      {"new", gettext("Back to new"), @neutral},
      {"discarded", gettext("Discard"), @discard}
    ]

  def actions_for("read"), do: [{"new", gettext("Back to new"), @neutral}]
  def actions_for("discarded"), do: [{"new", gettext("Restore"), @neutral}]
  def actions_for(_status), do: []
end

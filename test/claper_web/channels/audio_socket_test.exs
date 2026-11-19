defmodule ClaperWeb.AudioSocketTest do
  use ExUnit.Case, async: true

  alias ClaperWeb.AudioSocket

  test "rejects non-binary tokens without raising an exception" do
    for token <- [nil, false, 123, [], %{"unexpected" => "value"}] do
      assert :error = AudioSocket.connect(%{"token" => token}, %Phoenix.Socket{}, %{})
    end
  end

  test "rejects absent and invalid tokens" do
    assert :error = AudioSocket.connect(%{}, %Phoenix.Socket{}, %{})
    assert :error = AudioSocket.connect(%{"token" => "invalid"}, %Phoenix.Socket{}, %{})
  end

  test "accepts a signed audio token and preserves its authorization scope" do
    token =
      Phoenix.Token.sign(ClaperWeb.Endpoint, "audio_token", %{
        user_id: 123,
        event_uuid: "synthetic-audio-event"
      })

    assert {:ok, socket} =
             AudioSocket.connect(%{"token" => token}, %Phoenix.Socket{}, %{})

    assert socket.assigns.user_id == 123
    assert socket.assigns.authorized_event_uuid == "synthetic-audio-event"
  end
end

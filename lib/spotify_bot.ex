defmodule SpotifyBot do
  @moduledoc """
  SpotifyBot keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  use TwitchChat.Bot

  require Logger

  alias SpotifyBot.SongQueue
  alias SpotifyBot.SpotifyClient
  alias TwitchChat.Events.Message

  @impl true
  def handle_event(%Message{message: "!spotify add " <> link} = event) do
    %{channel: channel, display_name: user} = event

    case link do
      "https://open.spotify.com/track" <> _ ->
        track = SpotifyClient.get_track!(link)
        artists = Enum.map_join(track["artists"], ", ", & &1["name"])

        case SongQueue.add(track["id"], user) do
          :ok -> say(channel, "@#{user} added 『#{artists} - #{track["name"]}』 to the queue")
          {:error, :max_total} -> say(channel, "@#{user} the queue is full")
          {:error, :max_per_user} -> say(channel, "@#{user} you can't add more songs")
          {:error, :no_consecutive} -> say(channel, "@#{user} you can't add two songs in a row")
        end

      _ ->
        say(channel, "@#{user} must be a single spotify track")
    end
  end
end

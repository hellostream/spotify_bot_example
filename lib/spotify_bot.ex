defmodule SpotifyBot do
  @moduledoc """
  SpotifyBot keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  use TwitchChat.Bot

  require Logger

  alias SpotifyBot.SpotifyClient
  alias TwitchChat.Events.Message
  
  @impl true
  def handle_event(%Message{message: "!spotify add " <> link} = event) do
    %{channel: channel, display_name: user} = event

    case link do
      "https://open.spotify.com/track" <> _ ->
        {track, artists} = add_spotify_track(link)
        say(channel, "@#{user} added #{artists} - #{track["name"]} to queue")

      _ ->
        say(channel, "@#{user} must be a single spotify track")
    end
  end

  defp add_spotify_track(link) do
    track = SpotifyClient.get_track!(link)
    artists = Enum.map_join(track["artists"], ", ", & &1["name"])
    SpotifyClient.add_track_to_queue!(track["id"])
    
    {track, artists}
  end
end

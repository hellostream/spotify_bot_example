defmodule SpotifyBot.SpotifyClient do

  @base_url "https://api.spotify.com/v1"

  def get_access_token!(client_id, client_secret, refresh_token) do
    Req.post!(
      url: "https://accounts.spotify.com/api/token",
      auth: {:basic, "#{client_id}:#{client_secret}"},
      form: %{
        grant_type: "refresh_token",
        refresh_token: refresh_token
      }
    )
  end

  def get_track!("https://open.spotify.com/track/" <> rest) do
    rest
    |> String.split("?")
    |> List.first()
    |> get_track!()
  end

  def get_track!(id) when is_binary(id) do
    Req.get!(client(), url: "/tracks/#{id}").body
  end

  def add_track_to_queue!(track_id) do
    Req.post!(client(),
      url: "/me/player/queue",
      headers: %{"content-length" => 0},
      params: [uri: "spotify:track:#{track_id}"]
    )
  end

  # ----------------------------------------------------------------------------
  # Helpers
  # ----------------------------------------------------------------------------

  defp client do
    Req.new(base_url: @base_url)
    |> Req.Request.append_request_steps(add_token: &add_token/1)
  end

  defp add_token(request) do
    config = Application.fetch_env!(:spotify_bot, __MODULE__)
    client_id = Keyword.fetch!(config, :client_id)
    client_secret = Keyword.fetch!(config, :client_secret)
    refresh_token = Keyword.fetch!(config, :refresh_token)

    token = get_access_token!(client_id, client_secret, refresh_token).body["access_token"]

    Req.Request.put_header(request, "authorization", "Bearer #{token}")
  end
end
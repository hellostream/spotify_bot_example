# SpotifyBot

An example of using `:twitch_chat` to make a bot that adds songs to your spotify queue.

### Setup

#### Config

You need to set the following environment variables:

 * `SPOTIFY_CLIENT_ID`
 * `SPOTIFY_CLIENT_SECRET`
 * `SPOTIFY_REFRESH_TOKEN`
 * `TWITCH_USER`
 * `TWITCH_OAUTH_TOKEN`

##### Spotify:

To get the spotify token, you can use [https://github.com/alecchendev/spotify-refresh-token](https://github.com/alecchendev/spotify-refresh-token).

You need `user-modify-playback-state` scope to add songs to the queue.

##### Twitch:

To get the twitch oauth token, you can use https://twitchapps.com/tmi/

#### To start your application:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
  * Start without phoenix with `mix run --no-halt` or inside IEx with `iex -S mix`

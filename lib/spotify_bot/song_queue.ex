defmodule SpotifyBot.SongQueue do
  @moduledoc false
  use GenServer

  # Defaults.
  @allow_consecutive false
  @max_per_user 2
  @max_total 50

  @doc """
  Start the song queue server.

  ## Options

   * `:max_total` - The max total queue size. Defaults to `100`.
   * `:max_per_user` - The max number of songs per user. Defaults to `2`.
   * `:allow_consecutive?` - Whether we allow consecutives per user. Defaults to `false`.

  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Add a track to the queue.
  """
  @spec add(String.t(), String.t()) ::
          :ok
          | {:error, :max_total}
          | {:error, :max_per_user}
          | {:error, :no_consecutive}
  def add(track_id, user) do
    GenServer.call(__MODULE__, {:add, track_id, user})
  end

  @doc """
  Remove a track from the queue.
  """
  @spec remove(String.t()) :: :ok
  def remove(track_id) do
    GenServer.cast(__MODULE__, {:remove, track_id})
  end

  @doc """
  Remove all tracks for a user.
  """
  @spec remove_user(String.t()) :: :ok
  def remove_user(user) do
    GenServer.cast(__MODULE__, {:remove_user, user})
  end

  @doc """
  Get the length of the current queue.
  """
  @spec length() :: non_neg_integer()
  def length do
    GenServer.call(__MODULE__, :length)
  end

  # ----------------------------------------------------------------------------
  # Callbacks
  # ----------------------------------------------------------------------------

  @doc false
  @impl GenServer
  def init(opts) do
    state = %{
      allow_consecutive?: Keyword.get(opts, :allow_consecutive?, @allow_consecutive),
      max_total: Keyword.get(opts, :max_total, @max_total),
      max_per_user: Keyword.get(opts, :max_per_user, @max_per_user),
      queue: []
    }

    {:ok, state}
  end

  @doc false
  @impl GenServer
  def handle_cast({:remove, track_id}, state) do
    state =
      if List.keymember?(state.queue, track_id, 0) do
        # I know this is stupid. I want to remove the last occurence and I
        # don't want to use my brain. I'm tired. Leave me alone.
        queue = Enum.reverse(state.queue) |> List.keydelete(track_id, 0)
        %{state | queue: Enum.reverse(queue)}
      else
        state
      end

    {:noreply, state}
  end

  def handle_cast({:remove_user, user}, state) do
    if List.keymember?(state.queue, user, 1) do
      queue =
        Enum.reduce(state.queue, [], fn {track, u}, queue ->
          if user == u, do: queue, else: [{track, u} | queue]
        end)

      {:noreply, %{state | queue: queue}}
    else
      {:noreply, state}
    end
  end

  @doc false
  @impl GenServer
  def handle_call({:add, track_id, user}, _from, state) do
    {current_track, actual_tracks} = SpotifyBot.SpotifyClient.get_queue!()
    queue = sync_queue(state.queue, current_track, actual_tracks)
    total = Enum.count(queue)
    user_count = Enum.count(queue, &match?({_, ^user}, &1))

    cond do
      total >= state.max_total ->
        {:reply, {:error, :max_total}, state}

      user_count >= state.max_per_user ->
        {:reply, {:error, :max_per_user}, state}

      match?([{_, ^user} | _], queue) and not state.allow_consecutive? ->
        {:reply, {:error, :no_consecutive}, state}

      true ->
        SpotifyBot.SpotifyClient.add_track_to_queue!(track_id)
        {:reply, :ok, %{state | queue: [{track_id, user} | queue]}}
    end
  end

  def handle_call(:length, _from, state) do
    {:reply, Enum.count(state.queue), state}
  end

  defp sync_queue(current_queue, current_track, actual_queue) do
    # We reverse it so that `List.keytake/3` will return the last occurence
    # instead of the first.
    current_queue = Enum.reverse(current_queue)

    # The actual tracks are the source of truth. Go through these ones and
    # check for existing queue entries that match the tracks. If it exists in
    # the existing queue, it stays, if not, it gets added with a `nil` user.
    # Any tracks that are left over in the existing queue are not included.
    {queue, _} =
      [current_track | actual_queue]
      |> Enum.reduce({[], current_queue}, fn track_id, {acc, queue} ->
        case List.keytake(queue, track_id, 0) do
          {item, queue} ->
            {[item | acc], queue}

          nil ->
            {[{track_id, nil} | acc], queue}
        end
      end)

    queue
  end
end

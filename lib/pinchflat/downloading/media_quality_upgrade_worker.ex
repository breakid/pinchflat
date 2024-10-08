defmodule Pinchflat.Downloading.MediaQualityUpgradeWorker do
  @moduledoc false

  use Oban.Worker,
    queue: :media_fetching,
    unique: [period: :infinity, states: [:available, :scheduled, :retryable, :executing]],
    tags: ["media_item", "media_fetching", "show_in_dashboard"]

  require Logger

  alias Pinchflat.Media
  alias Pinchflat.Downloading.MediaDownloadWorker

  @doc """
  Redownloads media items that are eligible for redownload for the purpose
  of upgrading the quality of the media or improving things like sponsorblock
  segments.

  This worker is scheduled to run daily via the Oban Cron plugin
  and it should run _after_ the retention worker.

  Returns :ok
  """
  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    upgradable_media = Media.list_upgradeable_media_items()
    Logger.info("Redownloading #{length(upgradable_media)} media items")

    Enum.each(upgradable_media, fn media_item ->
      MediaDownloadWorker.kickoff_with_task(media_item, %{quality_upgrade?: true})
    end)
  end
end

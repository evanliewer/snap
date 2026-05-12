class GameSerializer
  include Rails.application.routes.url_helpers

  def initialize(game, viewer: nil, detail: false)
    @game = game
    @viewer = viewer
    @detail = detail
  end

  def as_json(*)
    base = {
      id: @game.id,
      title: @game.title,
      description: @game.description,
      join_code: @game.join_code,
      status: @game.status,
      starts_at: @game.starts_at,
      ends_at: @game.ends_at,
      allow_video: @game.allow_video,
      show_leaderboard: @game.show_leaderboard,
      auto_approve: @game.auto_approve,
      owner: { id: @game.owner.id, name: @game.owner.name },
      cover_url: cover_url
    }
    if @detail
      membership = @game.membership_for(@viewer)
      base[:membership] = membership && { role: membership.role, team_id: membership.team_id }
      base[:team_count] = @game.teams.count
      base[:mission_count] = @game.missions.count
      base[:player_count] = @game.memberships.count
    end
    base
  end

  private

  def cover_url
    return nil unless @game.cover_image.attached?
    rails_blob_url(@game.cover_image, host: default_host)
  rescue ArgumentError
    nil
  end

  def default_host
    Rails.application.routes.default_url_options[:host] || "localhost"
  end
end

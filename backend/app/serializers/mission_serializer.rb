class MissionSerializer
  def initialize(mission, viewer_team_id: nil)
    @mission = mission
    @viewer_team_id = viewer_team_id
  end

  def as_json(*)
    team_submissions = @viewer_team_id ? @mission.submissions.where(team_id: @viewer_team_id) : Mission.none
    {
      id: @mission.id,
      game_id: @mission.game_id,
      category_id: @mission.mission_category_id,
      category_name: @mission.mission_category&.name,
      category_color: @mission.mission_category&.color,
      title: @mission.title,
      description: @mission.description,
      points: @mission.points,
      bonus_points: @mission.bonus_points,
      first_bonus_count: @mission.first_bonus_count,
      first_bonus_points: @mission.first_bonus_points,
      mission_type: @mission.mission_type,
      position: @mission.position,
      required: @mission.required,
      repeatable: @mission.repeatable,
      max_submissions_per_team: @mission.max_submissions_per_team,
      requires_location: @mission.requires_location,
      available_from: @mission.available_from,
      available_until: @mission.available_until,
      hotspot_latitude: @mission.hotspot_latitude,
      hotspot_longitude: @mission.hotspot_longitude,
      hotspot_radius_m: @mission.hotspot_radius_m,
      available_now: @mission.available_now?,
      completed_by_team: team_submissions.where(status: %w[approved pending]).exists?,
      team_submission_count: team_submissions.count
    }
  end
end

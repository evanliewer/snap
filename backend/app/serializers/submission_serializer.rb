class SubmissionSerializer
  include Rails.application.routes.url_helpers

  def initialize(submission, viewer: nil)
    @submission = submission
    @viewer = viewer
  end

  def as_json(*)
    counts = @submission.reaction_counts
    {
      id: @submission.id,
      mission_id: @submission.mission_id,
      mission_title: @submission.mission.title,
      team_id: @submission.team_id,
      team_name: @submission.team.name,
      team_color: @submission.team.color,
      user: { id: @submission.user_id, name: @submission.user.name },
      caption: @submission.caption,
      latitude: @submission.latitude,
      longitude: @submission.longitude,
      status: @submission.status,
      points_awarded: @submission.points_awarded,
      created_at: @submission.created_at,
      photo_url: media_url(@submission.photo),
      video_url: media_url(@submission.video),
      reaction_counts: counts,
      reaction_total: counts.values.sum,
      my_reactions: @submission.reacted_kinds_by(@viewer),
      comment_count: @submission.comments.size
    }
  end

  private

  def media_url(attachment)
    return nil unless attachment.attached?
    rails_blob_url(attachment, host: Rails.application.routes.default_url_options[:host] || "localhost",
                   port: Rails.application.routes.default_url_options[:port])
  rescue ArgumentError
    nil
  end
end

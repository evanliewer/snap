class ActivityChannel < ApplicationCable::Channel
  def subscribed
    game_id = params[:game_id].to_i
    game = Game.find_by(id: game_id)
    return reject unless game && (game.owner_id == current_user.id || game.memberships.exists?(user_id: current_user.id))
    stream_for game
  end

  def unsubscribed; end

  def self.broadcast_submission(submission)
    payload = {
      type: "submission.created",
      submission: SubmissionSerializer.new(submission).as_json
    }
    broadcast_to(submission.mission.game, payload)
  end

  def self.broadcast_submission_updated(submission)
    payload = {
      type: "submission.updated",
      submission: SubmissionSerializer.new(submission).as_json
    }
    broadcast_to(submission.mission.game, payload)
  end
end

module Api
  module V1
    class SubmissionsController < BaseController
      before_action :load_mission

      # POST /api/v1/missions/:mission_id/submissions
      # multipart: photo (file), caption, latitude, longitude
      def create
        membership = @mission.game.membership_for(current_user)
        return render json: { error: "Not a member" }, status: :forbidden unless membership
        return render json: { error: "Join a team first" }, status: :unprocessable_entity unless membership.team_id

        submission = @mission.submissions.new(
          team_id: membership.team_id,
          user: current_user,
          caption: params[:caption],
          latitude: params[:latitude],
          longitude: params[:longitude]
        )

        if params[:photo].present?
          submission.photo.attach(params[:photo])
        end
        if params[:video].present?
          submission.video.attach(params[:video])
        end

        if submission.save
          render json: SubmissionSerializer.new(submission).as_json, status: :created
        else
          render_record_errors(submission)
        end
      end

      # GET /api/v1/missions/:mission_id/submissions
      def index
        membership = @mission.game.membership_for(current_user)
        return render json: { error: "Not a member" }, status: :forbidden unless membership
        scope = @mission.submissions.includes(:team, :user, photo_attachment: :blob).recent.limit(100)
        scope = scope.where(team_id: membership.team_id) unless @mission.game.admin?(current_user)
        render json: { submissions: scope.map { |s| SubmissionSerializer.new(s).as_json } }
      end

      private

      def load_mission
        @mission = Mission.find(params[:mission_id])
      end
    end
  end
end

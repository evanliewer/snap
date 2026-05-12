module Api
  module V1
    class SubmissionsController < BaseController
      before_action :load_mission, only: %i[create index_for_mission]
      before_action :load_game, only: %i[index_for_game]
      before_action :load_submission, only: %i[update destroy]
      before_action :require_admin_for_review, only: %i[update destroy]

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
          ActivityChannel.broadcast_submission(submission)
          render json: SubmissionSerializer.new(submission).as_json, status: :created
        else
          render_record_errors(submission)
        end
      end

      # GET /api/v1/missions/:mission_id/submissions
      def index_for_mission
        membership = @mission.game.membership_for(current_user)
        return render json: { error: "Not a member" }, status: :forbidden unless membership
        scope = @mission.submissions.includes(:team, :user, photo_attachment: :blob).recent.limit(100)
        scope = scope.where(team_id: membership.team_id) unless @mission.game.admin?(current_user)
        render json: { submissions: scope.map { |s| SubmissionSerializer.new(s).as_json } }
      end

      # GET /api/v1/games/:game_id/submissions[?status=pending]
      def index_for_game
        return render json: { error: "Game admin permission required" }, status: :forbidden unless @game.admin?(current_user)
        scope = @game.submissions.includes(:team, :user, :mission, photo_attachment: :blob).recent.limit(200)
        scope = scope.where(status: params[:status]) if params[:status].present?
        render json: { submissions: scope.map { |s| SubmissionSerializer.new(s).as_json } }
      end

      # PATCH /api/v1/submissions/:id
      # body: { submission: { status: "approved" | "rejected", points_awarded?: Int, review_notes?: String } }
      def update
        attrs = submission_review_params
        if attrs[:status].present?
          attrs[:reviewed_by_id] = current_user.id
          attrs[:reviewed_at]    = Time.current
          # Default points when approving and caller didn't specify
          if attrs[:status] == "approved" && attrs[:points_awarded].nil?
            attrs[:points_awarded] = @submission.mission.points
          end
          if attrs[:status] == "rejected"
            attrs[:points_awarded] = 0
          end
        end
        if @submission.update(attrs)
          ActivityChannel.broadcast_submission_updated(@submission)
          render json: SubmissionSerializer.new(@submission).as_json
        else
          render_record_errors(@submission)
        end
      end

      # DELETE /api/v1/submissions/:id
      def destroy
        @submission.destroy
        head :no_content
      end

      private

      def submission_review_params
        params.require(:submission).permit(:status, :points_awarded, :review_notes)
      end

      def load_mission
        @mission = Mission.find(params[:mission_id])
      end

      def load_game
        @game = Game.find(params[:game_id])
      end

      def load_submission
        @submission = Submission.find(params[:id])
      end

      def require_admin_for_review
        return if @submission.mission.game.admin?(current_user)
        render json: { error: "Game admin permission required" }, status: :forbidden
      end
    end
  end
end

module Api
  module V1
    class ReactionsController < BaseController
      before_action :load_submission

      # POST /api/v1/submissions/:submission_id/reactions  body: { kind: "heart" }
      def create
        return forbid unless member?
        kind = (params[:kind].presence || "heart").to_s
        return render json: { error: "Invalid kind" }, status: :unprocessable_entity unless Reaction::KINDS.include?(kind)
        Reaction.find_or_create_by!(submission: @submission, user: current_user, kind: kind)
        render json: reactions_payload, status: :created
      end

      # DELETE /api/v1/submissions/:submission_id/reactions  body: { kind: "heart" }
      def destroy
        return forbid unless member?
        kind = (params[:kind].presence || "heart").to_s
        Reaction.where(submission: @submission, user: current_user, kind: kind).destroy_all
        render json: reactions_payload
      end

      private

      def load_submission
        @submission = Submission.find(params[:submission_id])
      end

      def member?
        game = @submission.mission.game
        game.owner_id == current_user.id || game.memberships.exists?(user_id: current_user.id)
      end

      def forbid
        render json: { error: "Not a member" }, status: :forbidden
      end

      def reactions_payload
        {
          submission_id: @submission.id,
          counts: @submission.reaction_counts,
          mine: @submission.reacted_kinds_by(current_user)
        }
      end
    end
  end
end

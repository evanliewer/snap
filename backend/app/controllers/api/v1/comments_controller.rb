module Api
  module V1
    class CommentsController < BaseController
      before_action :load_submission, only: %i[index create]
      before_action :load_comment,    only: %i[destroy]

      # GET /api/v1/submissions/:submission_id/comments
      def index
        return forbid unless member?(@submission.mission.game)
        comments = @submission.comments.includes(:user).recent
        render json: { comments: comments.map { |c| comment_payload(c) } }
      end

      # POST /api/v1/submissions/:submission_id/comments  body: { body: "..." }
      def create
        return forbid unless member?(@submission.mission.game)
        body = params[:body].to_s.strip
        return render json: { error: "Comment is empty" }, status: :unprocessable_entity if body.empty?
        comment = @submission.comments.create!(user: current_user, body: body)
        render json: comment_payload(comment), status: :created
      end

      # DELETE /api/v1/comments/:id
      def destroy
        game = @comment.submission.mission.game
        return forbid unless @comment.user_id == current_user.id || game.admin?(current_user)
        @comment.destroy
        head :no_content
      end

      private

      def load_submission
        @submission = Submission.find(params[:submission_id])
      end

      def load_comment
        @comment = Comment.find(params[:id])
      end

      def member?(game)
        game.owner_id == current_user.id || game.memberships.exists?(user_id: current_user.id)
      end

      def forbid
        render json: { error: "Not authorized" }, status: :forbidden
      end

      def comment_payload(c)
        {
          id: c.id,
          submission_id: c.submission_id,
          user: { id: c.user_id, name: c.user.name },
          body: c.body,
          created_at: c.created_at
        }
      end
    end
  end
end

module Web
  class SubmissionsController < BaseController
    before_action :load_submission, only: %i[update destroy]
    before_action :load_game_from_submission, only: %i[update destroy]

    def index
      @game = Game.find(params[:game_id])
      redirect_to @game, alert: "Not authorized." and return unless @game.admin?(current_user)
      @submissions = @game.submissions.includes(:mission, :team, :user, photo_attachment: :blob).recent
    end

    def update
      redirect_to @submission.mission.game, alert: "Not authorized." and return unless @submission.mission.game.admin?(current_user)

      params_attrs = submission_params
      if params_attrs[:status].present?
        params_attrs[:reviewed_by_id] = current_user.id
        params_attrs[:reviewed_at] = Time.current
      end
      if @submission.update(params_attrs)
        redirect_back fallback_location: @submission.mission.game, notice: "Submission updated."
      else
        redirect_back fallback_location: @submission.mission.game, alert: @submission.errors.full_messages.to_sentence
      end
    end

    def destroy
      redirect_to @submission.mission.game, alert: "Not authorized." and return unless @submission.mission.game.admin?(current_user)
      game = @submission.mission.game
      @submission.destroy
      redirect_to game, notice: "Submission deleted."
    end

    private

    def load_submission
      @submission = Submission.find(params[:id])
    end

    def load_game_from_submission
      @game = @submission.mission.game
    end

    def submission_params
      params.require(:submission).permit(:status, :points_awarded, :review_notes)
    end
  end
end

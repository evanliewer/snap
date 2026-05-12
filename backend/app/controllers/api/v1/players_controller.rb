module Api
  module V1
    class PlayersController < BaseController
      before_action :load_game
      before_action :require_member

      # GET /api/v1/games/:game_id/players/:id
      def show
        user = User.find(params[:id])
        membership = @game.memberships.find_by(user_id: user.id)
        return render json: { error: "Not a player in this game" }, status: :not_found unless membership

        team = membership.team
        submissions = user.submissions.joins(:mission).where(missions: { game_id: @game.id })
                          .includes(:mission, :team, photo_attachment: :blob).recent.limit(100)
        total_points = submissions.where(status: "approved").sum(:points_awarded)
        render json: {
          user: { id: user.id, name: user.name },
          game_id: @game.id,
          team: team && { id: team.id, name: team.name, color: team.color },
          role: membership.role,
          total_points: total_points,
          submission_count: submissions.count,
          submissions: submissions.map { |s| SubmissionSerializer.new(s).as_json }
        }
      end

      private

      def load_game
        @game = Game.find(params[:game_id])
      end

      def require_member
        return if @game.owner_id == current_user.id || @game.memberships.exists?(user_id: current_user.id)
        render json: { error: "Not a member of this game" }, status: :forbidden
      end
    end
  end
end

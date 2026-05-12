module Api
  module V1
    class TeamsController < BaseController
      before_action :load_game

      # GET /api/v1/games/:game_id/teams
      def index
        teams = @game.teams.order(:name)
        render json: { teams: teams.map { |t| team_payload(t) } }
      end

      # POST /api/v1/games/:game_id/teams  (admin only)
      def create
        return forbid unless @game.admin?(current_user)
        team = @game.teams.new(team_params)
        if team.save
          render json: team_payload(team), status: :created
        else
          render_record_errors(team)
        end
      end

      # POST /api/v1/games/:game_id/teams/:id/join
      def join
        team = @game.teams.find(params[:id])
        membership = @game.memberships.find_by(user: current_user)
        return render json: { error: "Not a member" }, status: :forbidden unless membership
        membership.update!(team: team)
        render json: team_payload(team)
      end

      private

      def team_params
        params.require(:team).permit(:name, :color)
      end

      def load_game
        @game = Game.find(params[:game_id])
      end

      def forbid
        render json: { error: "Admins only" }, status: :forbidden
      end

      def team_payload(team)
        {
          id: team.id,
          name: team.name,
          color: team.color,
          member_count: team.memberships.count,
          points: team.total_points
        }
      end
    end
  end
end

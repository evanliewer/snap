module Api
  module V1
    class TeamsController < BaseController
      before_action :load_game
      before_action :load_team, only: %i[update destroy join]
      before_action :require_admin, only: %i[create update destroy]

      # GET /api/v1/games/:game_id/teams
      def index
        teams = @game.teams.order(:name)
        render json: { teams: teams.map { |t| team_payload(t) } }
      end

      # POST /api/v1/games/:game_id/teams
      def create
        team = @game.teams.new(team_params)
        if team.save
          render json: team_payload(team), status: :created
        else
          render_record_errors(team)
        end
      end

      # PATCH /api/v1/games/:game_id/teams/:id
      def update
        if @team.update(team_params)
          render json: team_payload(@team)
        else
          render_record_errors(@team)
        end
      end

      # DELETE /api/v1/games/:game_id/teams/:id
      def destroy
        @team.destroy
        head :no_content
      end

      # POST /api/v1/games/:game_id/teams/:id/join
      def join
        membership = @game.memberships.find_by(user: current_user)
        return render json: { error: "Not a member" }, status: :forbidden unless membership
        membership.update!(team: @team)
        render json: team_payload(@team)
      end

      private

      def team_params
        params.require(:team).permit(:name, :color)
      end

      def load_game
        @game = Game.find(params[:game_id])
      end

      def load_team
        @team = @game.teams.find(params[:id])
      end

      def require_admin
        return if @game.admin?(current_user)
        render json: { error: "Game admin permission required" }, status: :forbidden
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

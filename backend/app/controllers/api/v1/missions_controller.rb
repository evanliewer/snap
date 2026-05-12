module Api
  module V1
    class MissionsController < BaseController
      before_action :load_game

      # GET /api/v1/games/:game_id/missions
      def index
        missions = @game.missions.includes(:mission_category, :submissions).by_position
        membership = @game.membership_for(current_user)
        team_id = membership&.team_id
        payload = missions.map do |m|
          MissionSerializer.new(m, viewer_team_id: team_id).as_json
        end
        categories = @game.mission_categories.map do |c|
          { id: c.id, name: c.name, color: c.color, position: c.position }
        end
        render json: { categories: categories, missions: payload }
      end

      private

      def load_game
        @game = Game.find(params[:game_id])
        unless @game.memberships.exists?(user_id: current_user.id) || @game.owner_id == current_user.id
          render json: { error: "Not a member of this game" }, status: :forbidden and return
        end
      end
    end
  end
end

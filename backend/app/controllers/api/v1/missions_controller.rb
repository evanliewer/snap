module Api
  module V1
    class MissionsController < BaseController
      before_action :load_game
      before_action :load_mission, only: %i[update destroy]
      before_action :require_admin, only: %i[create update destroy]

      # GET /api/v1/games/:game_id/missions
      def index
        return forbid_member unless member?
        missions = @game.missions.includes(:mission_category, :submissions).by_position
        membership = @game.membership_for(current_user)
        team_id = membership&.team_id
        payload = missions.map { |m| MissionSerializer.new(m, viewer_team_id: team_id).as_json }
        categories = @game.mission_categories.map { |c| { id: c.id, name: c.name, color: c.color, position: c.position } }
        render json: { categories: categories, missions: payload }
      end

      # POST /api/v1/games/:game_id/missions
      def create
        mission = @game.missions.new(mission_params)
        mission.position ||= @game.missions.count
        if mission.save
          render json: MissionSerializer.new(mission).as_json, status: :created
        else
          render_record_errors(mission)
        end
      end

      # PATCH /api/v1/games/:game_id/missions/:id
      def update
        if @mission.update(mission_params)
          render json: MissionSerializer.new(@mission).as_json
        else
          render_record_errors(@mission)
        end
      end

      # DELETE /api/v1/games/:game_id/missions/:id
      def destroy
        @mission.destroy
        head :no_content
      end

      # POST /api/v1/games/:game_id/missions/reorder  body: { ids: [3, 1, 2] }
      def reorder
        return require_admin unless @game.admin?(current_user)
        ids = Array(params[:ids]).map(&:to_i)
        Mission.transaction do
          ids.each_with_index do |id, idx|
            @game.missions.where(id: id).update_all(position: idx)
          end
        end
        head :no_content
      end

      private

      def mission_params
        params.require(:mission).permit(
          :title, :description, :points, :bonus_points, :mission_type, :position,
          :required, :repeatable, :max_submissions_per_team, :requires_location, :mission_category_id,
          :available_from, :available_until,
          :hotspot_latitude, :hotspot_longitude, :hotspot_radius_m,
          :first_bonus_count, :first_bonus_points
        )
      end

      def load_game
        @game = Game.find(params[:game_id])
      end

      def load_mission
        @mission = @game.missions.find(params[:id])
      end

      def member?
        @game.owner_id == current_user.id || @game.memberships.exists?(user_id: current_user.id)
      end

      def forbid_member
        render json: { error: "Not a member of this game" }, status: :forbidden
      end

      def require_admin
        return if @game.admin?(current_user)
        render json: { error: "Game admin permission required" }, status: :forbidden
      end
    end
  end
end

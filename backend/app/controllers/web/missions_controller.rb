module Web
  class MissionsController < BaseController
    before_action :load_game
    before_action :require_admin
    before_action :load_mission, only: %i[edit update destroy]

    def index
      @missions = @game.missions.includes(:mission_category).by_position
    end

    def new
      @mission = @game.missions.new(points: 100, mission_type: "photo", max_submissions_per_team: 1, position: @game.missions.count)
    end

    def create
      @mission = @game.missions.new(mission_params)
      if @mission.save
        redirect_to game_missions_path(@game), notice: "Mission created."
      else
        flash.now[:alert] = @mission.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @mission.update(mission_params)
        redirect_to game_missions_path(@game), notice: "Mission updated."
      else
        flash.now[:alert] = @mission.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @mission.destroy
      redirect_to game_missions_path(@game), notice: "Mission removed."
    end

    private

    def load_game
      @game = Game.find(params[:game_id])
    end

    def load_mission
      @mission = @game.missions.find(params[:id])
    end

    def mission_params
      params.require(:mission).permit(:title, :description, :points, :bonus_points, :mission_type, :position, :required, :repeatable, :max_submissions_per_team, :requires_location, :mission_category_id)
    end

    def require_admin
      redirect_to @game, alert: "Not authorized." unless @game.admin?(current_user)
    end
  end
end

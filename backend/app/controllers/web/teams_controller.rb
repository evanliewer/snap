module Web
  class TeamsController < BaseController
    before_action :load_game
    before_action :require_admin
    before_action :load_team, only: %i[edit update destroy]

    def index
      @teams = @game.teams.order(:name)
    end

    def new
      @team = @game.teams.new
    end

    def create
      @team = @game.teams.new(team_params)
      if @team.save
        redirect_to game_teams_path(@game), notice: "Team #{@team.name} added."
      else
        flash.now[:alert] = @team.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @team.update(team_params)
        redirect_to game_teams_path(@game), notice: "Team updated."
      else
        flash.now[:alert] = @team.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @team.destroy
      redirect_to game_teams_path(@game), notice: "Team removed."
    end

    private

    def load_game
      @game = Game.find(params[:game_id])
    end

    def load_team
      @team = @game.teams.find(params[:id])
    end

    def team_params
      params.require(:team).permit(:name, :color)
    end

    def require_admin
      redirect_to @game, alert: "Not authorized." unless @game.admin?(current_user)
    end
  end
end

module Web
  class GamesController < BaseController
    before_action :load_game, only: %i[show edit update destroy start end]
    before_action :require_admin, only: %i[edit update destroy start end]

    def index
      @games = current_user.owned_games.order(updated_at: :desc)
    end

    def new
      @game = current_user.owned_games.new(status: "draft", auto_approve: true, show_leaderboard: true)
    end

    def create
      @game = current_user.owned_games.new(game_params)
      if @game.save
        current_user.memberships.create!(game: @game, role: "admin")
        redirect_to @game, notice: "Game created. Join code: #{@game.join_code}"
      else
        flash.now[:alert] = @game.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @teams = @game.teams.order(:name)
      @missions = @game.missions.includes(:mission_category).by_position
      @categories = @game.mission_categories
      @submissions = @game.submissions.includes(:team, :user, :mission, photo_attachment: :blob).recent.limit(30)
      @leaderboard = @game.leaderboard.to_a
    end

    def edit; end

    def update
      if @game.update(game_params)
        redirect_to @game, notice: "Game updated."
      else
        flash.now[:alert] = @game.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @game.destroy
      redirect_to root_path, notice: "Game deleted."
    end

    def start
      @game.update!(status: "active", starts_at: @game.starts_at || Time.current)
      redirect_to @game, notice: "Game is live!"
    end

    def end
      @game.update!(status: "ended", ends_at: Time.current)
      redirect_to @game, notice: "Game ended."
    end

    private

    def game_params
      params.require(:game).permit(:title, :description, :starts_at, :ends_at, :allow_video, :show_leaderboard, :auto_approve, :cover_image, :status)
    end

    def load_game
      @game = Game.find(params[:id])
    end

    def require_admin
      redirect_to root_path, alert: "Not authorized." unless @game.admin?(current_user)
    end
  end
end

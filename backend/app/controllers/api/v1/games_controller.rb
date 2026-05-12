module Api
  module V1
    class GamesController < BaseController
      before_action :load_game, only: %i[show update destroy leaderboard activity start end]
      before_action :require_admin, only: %i[update destroy start end]

      # POST /api/v1/games
      def create
        game = current_user.owned_games.new(game_params.merge(status: params[:status].presence || "draft"))
        if game.save
          current_user.memberships.create!(game: game, role: "admin")
          render json: GameSerializer.new(game, viewer: current_user, detail: true).as_json, status: :created
        else
          render_record_errors(game)
        end
      end

      # POST /api/v1/games/join  body: { join_code: "ABC123" }
      def join
        code = params[:join_code].to_s.upcase.strip
        game = Game.find_by(join_code: code)
        return render json: { error: "Game not found" }, status: :not_found unless game

        membership = game.memberships.find_or_initialize_by(user: current_user)
        membership.role ||= "player"
        membership.save!
        render json: GameSerializer.new(game, viewer: current_user).as_json.merge(membership: { role: membership.role, team_id: membership.team_id })
      end

      # GET /api/v1/games/:id
      def show
        render json: GameSerializer.new(@game, viewer: current_user, detail: true).as_json
      end

      # PATCH /api/v1/games/:id
      def update
        if @game.update(game_params)
          render json: GameSerializer.new(@game, viewer: current_user, detail: true).as_json
        else
          render_record_errors(@game)
        end
      end

      # DELETE /api/v1/games/:id
      def destroy
        return render json: { error: "Only the owner can delete the game" }, status: :forbidden unless @game.owner_id == current_user.id
        @game.destroy
        head :no_content
      end

      # POST /api/v1/games/:id/start
      def start
        @game.update!(status: "active", starts_at: @game.starts_at || Time.current)
        render json: GameSerializer.new(@game, viewer: current_user, detail: true).as_json
      end

      # POST /api/v1/games/:id/end
      def end
        @game.update!(status: "ended", ends_at: Time.current)
        render json: GameSerializer.new(@game, viewer: current_user, detail: true).as_json
      end

      # GET /api/v1/games/:id/leaderboard
      def leaderboard
        teams = @game.leaderboard
        render json: {
          game_id: @game.id,
          teams: teams.map do |t|
            {
              id: t.id,
              name: t.name,
              color: t.color,
              points: t.attributes["total_points"].to_i,
              submissions: t.attributes["submission_count"].to_i
            }
          end
        }
      end

      # GET /api/v1/games/:id/activity
      def activity
        subs = @game.submissions.includes(:mission, :team, :user).recent.limit(50)
        render json: { events: subs.map { |s| SubmissionSerializer.new(s).as_json } }
      end

      private

      def game_params
        params.require(:game).permit(:title, :description, :starts_at, :ends_at, :allow_video, :show_leaderboard, :auto_approve)
      end

      def load_game
        @game = Game.find(params[:id])
        return if @game.memberships.exists?(user_id: current_user.id) || @game.owner_id == current_user.id
        render json: { error: "Not a member of this game" }, status: :forbidden
      end

      def require_admin
        return if @game.admin?(current_user)
        render json: { error: "Game admin permission required" }, status: :forbidden
      end
    end
  end
end

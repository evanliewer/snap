module Api
  module V1
    class GamesController < BaseController
      before_action :load_game, only: %i[show leaderboard activity]

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

      def load_game
        @game = Game.find(params[:id])
        unless @game.memberships.exists?(user_id: current_user.id) || @game.owner_id == current_user.id
          render json: { error: "Not a member of this game" }, status: :forbidden and return
        end
      end
    end
  end
end

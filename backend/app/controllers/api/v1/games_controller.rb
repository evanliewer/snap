module Api
  module V1
    class GamesController < BaseController
      before_action :load_game, only: %i[show update destroy leaderboard activity start end duplicate cover archive unarchive]
      before_action :require_admin, only: %i[update destroy start end duplicate cover archive unarchive]

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

      # POST /api/v1/games/:id/archive
      def archive
        @game.archive!
        render json: GameSerializer.new(@game, viewer: current_user, detail: true).as_json
      end

      # POST /api/v1/games/:id/unarchive
      def unarchive
        @game.unarchive!
        render json: GameSerializer.new(@game, viewer: current_user, detail: true).as_json
      end

      # POST /api/v1/games/:id/duplicate
      def duplicate
        new_game = nil
        ActiveRecord::Base.transaction do
          new_game = current_user.owned_games.create!(
            title: "#{@game.title} (copy)",
            description: @game.description,
            allow_video: @game.allow_video,
            show_leaderboard: @game.show_leaderboard,
            auto_approve: @game.auto_approve,
            status: "draft"
          )
          current_user.memberships.create!(game: new_game, role: "admin")

          category_map = {}
          @game.mission_categories.each do |c|
            new_c = new_game.mission_categories.create!(name: c.name, color: c.color, position: c.position)
            category_map[c.id] = new_c.id
          end

          @game.missions.each do |m|
            new_game.missions.create!(
              mission_category_id: category_map[m.mission_category_id],
              title: m.title,
              description: m.description,
              points: m.points,
              bonus_points: m.bonus_points,
              mission_type: m.mission_type,
              position: m.position,
              required: m.required,
              repeatable: m.repeatable,
              max_submissions_per_team: m.max_submissions_per_team,
              requires_location: m.requires_location
            )
          end
          # Teams: copy the names + colors but not members
          @game.teams.each do |t|
            new_game.teams.create!(name: t.name, color: t.color)
          end
        end
        render json: GameSerializer.new(new_game, viewer: current_user, detail: true).as_json, status: :created
      end

      # PATCH /api/v1/games/:id/cover  (multipart: cover_image)
      def cover
        if params[:cover_image].present?
          @game.cover_image.attach(params[:cover_image])
          render json: GameSerializer.new(@game, viewer: current_user, detail: true).as_json
        elsif params[:remove] == "1"
          @game.cover_image.purge
          render json: GameSerializer.new(@game, viewer: current_user, detail: true).as_json
        else
          render json: { error: "cover_image file required" }, status: :unprocessable_entity
        end
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

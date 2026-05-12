module Api
  module V1
    class GameTemplatesController < BaseController
      # GET /api/v1/game_templates
      def index
        render json: { templates: GameTemplate.all.map { |t| template_summary(t) } }
      end

      # POST /api/v1/games/:game_id/apply_template  body: { slug: "birthday" }
      def apply
        game = Game.find(params[:game_id])
        return render json: { error: "Game admin permission required" }, status: :forbidden unless game.admin?(current_user)

        template = GameTemplate.find(params[:slug].to_s)
        return render json: { error: "Unknown template" }, status: :not_found unless template

        template.apply_to!(game)
        render json: GameSerializer.new(game.reload, viewer: current_user, detail: true).as_json
      end

      private

      def template_summary(t)
        {
          slug: t.slug,
          title: t.title,
          description: t.description,
          category_count: t.categories.size,
          mission_count: t.missions.size,
          categories: t.categories.map { |c| { name: c[:name], color: c[:color] } },
          missions: t.missions.map { |m| { title: m[:title], points: m[:points] || 100, category: m[:category] } }
        }
      end
    end
  end
end

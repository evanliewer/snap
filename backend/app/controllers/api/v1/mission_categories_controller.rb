module Api
  module V1
    class MissionCategoriesController < BaseController
      before_action :load_game
      before_action :load_category, only: %i[update destroy]
      before_action :require_admin, only: %i[create update destroy]

      # GET /api/v1/games/:game_id/categories
      def index
        render json: { categories: @game.mission_categories.map { |c| category_payload(c) } }
      end

      # POST /api/v1/games/:game_id/categories
      def create
        category = @game.mission_categories.new(category_params)
        category.position ||= @game.mission_categories.count
        if category.save
          render json: category_payload(category), status: :created
        else
          render_record_errors(category)
        end
      end

      # PATCH /api/v1/games/:game_id/categories/:id
      def update
        if @category.update(category_params)
          render json: category_payload(@category)
        else
          render_record_errors(@category)
        end
      end

      # DELETE /api/v1/games/:game_id/categories/:id
      def destroy
        @category.destroy
        head :no_content
      end

      # POST /api/v1/games/:game_id/categories/reorder  body: { ids: [3, 1, 2] }
      def reorder
        return require_admin unless @game.admin?(current_user)
        ids = Array(params[:ids]).map(&:to_i)
        MissionCategory.transaction do
          ids.each_with_index do |id, idx|
            @game.mission_categories.where(id: id).update_all(position: idx)
          end
        end
        head :no_content
      end

      private

      def category_params
        params.require(:mission_category).permit(:name, :color, :position)
      end

      def load_game
        @game = Game.find(params[:game_id])
      end

      def load_category
        @category = @game.mission_categories.find(params[:id])
      end

      def require_admin
        return if @game.admin?(current_user)
        render json: { error: "Game admin permission required" }, status: :forbidden
      end

      def category_payload(category)
        {
          id: category.id,
          name: category.name,
          color: category.color,
          position: category.position
        }
      end
    end
  end
end

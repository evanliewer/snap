module Web
  class MissionCategoriesController < BaseController
    before_action :load_game
    before_action :require_admin
    before_action :load_category, only: %i[edit update destroy]

    def index
      @categories = @game.mission_categories
    end

    def new
      @mission_category = @game.mission_categories.new(position: @game.mission_categories.count)
    end

    def create
      @mission_category = @game.mission_categories.new(category_params)
      if @mission_category.save
        redirect_to game_mission_categories_path(@game), notice: "Category added."
      else
        flash.now[:alert] = @mission_category.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @mission_category.update(category_params)
        redirect_to game_mission_categories_path(@game), notice: "Category updated."
      else
        flash.now[:alert] = @mission_category.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @mission_category.destroy
      redirect_to game_mission_categories_path(@game), notice: "Category removed."
    end

    private

    def load_game
      @game = Game.find(params[:game_id])
    end

    def load_category
      @mission_category = @game.mission_categories.find(params[:id])
    end

    def category_params
      params.require(:mission_category).permit(:name, :color, :position)
    end

    def require_admin
      redirect_to @game, alert: "Not authorized." unless @game.admin?(current_user)
    end
  end
end

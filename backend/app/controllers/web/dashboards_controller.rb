module Web
  class DashboardsController < BaseController
    def show
      @owned_games = current_user.owned_games.order(updated_at: :desc)
      @joined_games = Game.joins(:memberships).where(memberships: { user_id: current_user.id }).where.not(owner_id: current_user.id).distinct
    end
  end
end

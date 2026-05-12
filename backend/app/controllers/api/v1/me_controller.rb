module Api
  module V1
    class MeController < BaseController
      def show
        render json: {
          user: UserSerializer.new(current_user).as_json,
          games: current_user.memberships.includes(game: :owner).map { |m| GameSerializer.new(m.game, viewer: current_user).as_json.merge(role: m.role, team_id: m.team_id) }
        }
      end
    end
  end
end

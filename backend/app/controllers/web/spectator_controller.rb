module Web
  class SpectatorController < ApplicationController
    include WebAuthentication
    layout "application"

    skip_before_action :require_login
    skip_before_action :verify_authenticity_token, raise: false

    def show
      @game = Game.find_by(join_code: params[:join_code].to_s.upcase)
      return render :not_found, status: :not_found unless @game

      @teams = @game.leaderboard.to_a
      @recent = @game.submissions
                     .includes(:team, :user, :mission, photo_attachment: :blob)
                     .where(status: "approved").recent.limit(40)
      @top_reactions = Submission.joins(:mission)
                                 .where(missions: { game_id: @game.id }, submissions: { status: "approved" })
                                 .left_joins(:reactions)
                                 .group("submissions.id")
                                 .order(Arel.sql("COUNT(reactions.id) DESC"))
                                 .limit(6)
                                 .includes(:team, :user, :mission, photo_attachment: :blob)
    end

    def recap
      @game = Game.find_by(join_code: params[:join_code].to_s.upcase)
      return render :not_found, status: :not_found unless @game

      @teams = @game.leaderboard.to_a
      @top_team = @teams.first
      @total_submissions = @game.submissions.where(status: "approved").count
      @total_players = @game.memberships.count
      @top_reactions = Submission.joins(:mission)
                                 .where(missions: { game_id: @game.id }, submissions: { status: "approved" })
                                 .left_joins(:reactions)
                                 .group("submissions.id")
                                 .order(Arel.sql("COUNT(reactions.id) DESC"))
                                 .limit(9)
                                 .includes(:team, :user, :mission, photo_attachment: :blob)
      @leader_per_mission = @game.missions.includes(:submissions).map do |m|
        winner = m.submissions.approved_or_pending.order(:created_at).first
        winner ? { mission: m, submission: winner } : nil
      end.compact.first(6)
    end
  end
end

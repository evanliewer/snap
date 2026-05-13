module Api
  module V1
    class PasswordResetsController < BaseController
      skip_before_action :authenticate_user!

      # POST /api/v1/password_resets  body: { email_address }
      # Always returns 200 so we don't leak whether a given email is registered.
      def create
        email = params[:email_address].to_s.downcase.strip
        user = User.find_by(email_address: email)
        if user
          reset = user.password_resets.create!
          # No SMTP configured yet — log it so an operator can deliver manually
          # or so it shows up in Rails logs / Render logs. Wire ActionMailer +
          # SMTP env vars once you're ready to send real emails.
          Rails.logger.info("[password_reset] token=#{reset.token} for user_id=#{user.id} email=#{user.email_address}")
        end
        render json: { status: "ok" }
      end

      # PATCH /api/v1/password_resets/:token  body: { password }
      def update
        reset = PasswordReset.find_by(token: params[:id])
        return render json: { error: "Invalid or expired link" }, status: :not_found unless reset
        return render json: { error: "Link expired" }, status: :unprocessable_entity if reset.expired?

        if reset.user.update(password: params[:password])
          reset.destroy
          render json: { status: "ok" }
        else
          render_record_errors(reset.user)
        end
      end
    end
  end
end

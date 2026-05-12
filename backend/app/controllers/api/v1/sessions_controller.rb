module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_user!, only: %i[create signup]

      # POST /api/v1/signup
      def signup
        user = User.new(signup_params)
        if user.save
          session = user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip)
          render json: auth_payload(user, session), status: :created
        else
          render_record_errors(user)
        end
      end

      # POST /api/v1/login
      def create
        user = User.find_by(email_address: params[:email_address].to_s.downcase.strip)
        if user&.authenticate(params[:password])
          session = user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip)
          render json: auth_payload(user, session)
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      # DELETE /api/v1/logout
      def destroy
        current_session&.destroy
        head :no_content
      end

      private

      def signup_params
        params.permit(:email_address, :password, :name)
      end

      def auth_payload(user, session)
        {
          token: session.token,
          user: UserSerializer.new(user).as_json
        }
      end
    end
  end
end

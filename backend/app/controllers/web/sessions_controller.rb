module Web
  class SessionsController < BaseController
    skip_before_action :require_login, only: %i[new create]

    def new
      redirect_to root_path if user_signed_in?
    end

    def create
      user = User.find_by(email_address: params[:email_address].to_s.downcase.strip)
      if user&.authenticate(params[:password])
        sign_in(user)
        redirect_to root_path, notice: "Welcome back, #{user.name}."
      else
        flash.now[:alert] = "Invalid email or password."
        render :new, status: :unauthorized
      end
    end

    def destroy
      sign_out
      redirect_to login_path, notice: "Signed out."
    end
  end
end

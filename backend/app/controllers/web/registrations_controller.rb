module Web
  class RegistrationsController < BaseController
    skip_before_action :require_login, only: %i[new create]

    def new
      @user = User.new
      redirect_to root_path if user_signed_in?
    end

    def create
      @user = User.new(registration_params)
      if @user.save
        sign_in(@user)
        redirect_to root_path, notice: "Account created. Let's build a game."
      else
        flash.now[:alert] = @user.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    private

    def registration_params
      params.require(:user).permit(:email_address, :password, :name)
    end
  end
end

module WebAuthentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :user_signed_in?, :current_session
    before_action :require_login
  end

  private

  def current_session
    return @current_session if defined?(@current_session)
    token = cookies.signed[:session_token]
    @current_session = token && Session.find_by(token: token)
  end

  def current_user
    current_session&.user
  end

  def user_signed_in?
    current_user.present?
  end

  def require_login
    return if user_signed_in?
    redirect_to login_path, alert: "Please log in to continue."
  end

  def sign_in(user)
    session = user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip)
    cookies.signed[:session_token] = { value: session.token, httponly: true, same_site: :lax, expires: 30.days.from_now }
    @current_session = session
  end

  def sign_out
    current_session&.destroy
    cookies.delete(:session_token)
    @current_session = nil
  end
end

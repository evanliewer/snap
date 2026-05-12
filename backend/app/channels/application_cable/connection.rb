module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.params[:token].to_s.presence ||
              request.headers["Authorization"].to_s.split(" ", 2).last
      session = token && Session.includes(:user).find_by(token: token)
      reject_unauthorized_connection unless session&.user
      session.user
    end
  end
end

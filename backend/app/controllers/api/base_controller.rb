module Api
  class BaseController < ActionController::API
    include ActionController::HttpAuthentication::Token::ControllerMethods

    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable
    rescue_from ActionController::ParameterMissing, with: :bad_request

    before_action :authenticate_user!

    attr_reader :current_user, :current_session

    def authenticate_user!
      authenticate_with_http_token do |token, _options|
        session = Session.includes(:user).find_by(token: token)
        if session
          @current_session = session
          @current_user = session.user
          return true
        end
      end
      render json: { error: "Unauthorized" }, status: :unauthorized
      false
    end

    private

    def not_found(exc)
      render json: { error: exc.message }, status: :not_found
    end

    def unprocessable(exc)
      render json: { error: exc.message, details: exc.record&.errors&.full_messages }, status: :unprocessable_entity
    end

    def bad_request(exc)
      render json: { error: exc.message }, status: :bad_request
    end

    def render_record_errors(record, status: :unprocessable_entity)
      render json: { error: record.errors.full_messages.to_sentence, details: record.errors.full_messages }, status: status
    end
  end
end

class ApplicationController < ActionController::Base
  allow_browser versions: :modern, if: -> { request.format.html? }
end

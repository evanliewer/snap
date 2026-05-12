module Web
  class BaseController < ApplicationController
    include WebAuthentication
    layout "application"

    protect_from_forgery with: :exception, prepend: true
  end
end

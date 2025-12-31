module Admin
  class BaseController < ActionController::Base
    protect_from_forgery with: :exception
    before_action :require_admin

    layout 'admin'

    helper_method :current_admin_user

    private

    def require_admin
      unless current_admin_user&.admin?
        flash[:alert] = 'You must be logged in as an admin to access this page.'
        redirect_to admin_login_path
      end
    end

    def current_admin_user
      @current_admin_user ||= User.find_by(id: session[:admin_user_id])
    end
  end
end

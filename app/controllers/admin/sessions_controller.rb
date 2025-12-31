module Admin
  class SessionsController < ActionController::Base
    protect_from_forgery with: :exception
    layout 'admin'

    def new
      redirect_to admin_root_path if current_admin_user&.admin?
    end

    def create
      user = User.find_by(email: params[:email]&.downcase)

      if user&.authenticate(params[:password]) && user.admin?
        session[:admin_user_id] = user.id

        AuditLog.log(
          action: 'admin_login',
          user: user,
          request: request
        )

        flash[:notice] = "Welcome back, #{user.first_name}!"
        redirect_to admin_root_path
      else
        flash.now[:alert] = 'Invalid email or password, or you do not have admin access.'
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      user = current_admin_user

      if user
        AuditLog.log(
          action: 'admin_logout',
          user: user,
          request: request
        )
      end

      session.delete(:admin_user_id)
      flash[:notice] = 'You have been logged out.'
      redirect_to admin_login_path
    end

    private

    def current_admin_user
      @current_admin_user ||= User.find_by(id: session[:admin_user_id])
    end
    helper_method :current_admin_user
  end
end

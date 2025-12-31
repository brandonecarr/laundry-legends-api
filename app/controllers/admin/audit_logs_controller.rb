module Admin
  class AuditLogsController < BaseController
    def index
      @audit_logs = AuditLog.includes(:user).recent

      # Filters
      if params[:action_type].present?
        @audit_logs = @audit_logs.by_action(params[:action_type])
      end

      if params[:user_id].present?
        @audit_logs = @audit_logs.by_user(params[:user_id])
      end

      if params[:date_from].present?
        @audit_logs = @audit_logs.where('audit_logs.created_at >= ?', Date.parse(params[:date_from]).beginning_of_day)
      end

      if params[:date_to].present?
        @audit_logs = @audit_logs.where('audit_logs.created_at <= ?', Date.parse(params[:date_to]).end_of_day)
      end

      @audit_logs = @audit_logs.page(params[:page]).per(50)

      @action_types = AuditLog::ACTIONS
    end
  end
end

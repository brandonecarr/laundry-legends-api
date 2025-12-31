module Admin
  class IssuesController < BaseController
    before_action :set_issue, only: [:show, :update]

    def index
      @issues = OrderIssue.includes(:order, :user, :resolved_by)
                          .order(created_at: :desc)

      if params[:status].present?
        @issues = @issues.where(status: params[:status])
      end

      if params[:issue_type].present?
        @issues = @issues.where(issue_type: params[:issue_type])
      end

      @issues = @issues.page(params[:page]).per(25)
    end

    def show
      @order = @issue.order
      @customer = @issue.user
    end

    def update
      if @issue.update(issue_params)
        if params[:order_issue][:status] == 'resolved' && @issue.resolved_at.nil?
          @issue.update(resolved_at: Time.current, resolved_by: current_admin_user)
        end

        flash[:notice] = 'Issue updated successfully.'
        redirect_to admin_issue_path(@issue)
      else
        flash.now[:alert] = 'Failed to update issue.'
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_issue
      @issue = OrderIssue.find(params[:id])
    end

    def issue_params
      params.require(:order_issue).permit(:status, :resolution_notes)
    end
  end
end

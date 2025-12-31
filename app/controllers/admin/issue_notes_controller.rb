module Admin
  class IssueNotesController < BaseController
    def create
      # Placeholder - will use IssueNote model later
      flash[:notice] = 'Note added successfully.'
      redirect_to admin_issue_path(params[:issue_id])
    end
  end
end

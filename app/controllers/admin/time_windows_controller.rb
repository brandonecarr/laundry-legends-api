module Admin
  class TimeWindowsController < BaseController
    before_action :set_time_window, only: [:edit, :update, :destroy]

    def index
      @time_windows = TimeWindow.order(:start_time)
    end

    def new
      @time_window = TimeWindow.new
    end

    def create
      @time_window = TimeWindow.new(time_window_params)

      if @time_window.save
        flash[:notice] = 'Time window created successfully.'
        redirect_to admin_time_windows_path
      else
        flash.now[:alert] = 'Failed to create time window.'
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @time_window.update(time_window_params)
        flash[:notice] = 'Time window updated successfully.'
        redirect_to admin_time_windows_path
      else
        flash.now[:alert] = 'Failed to update time window.'
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @time_window.destroy
      flash[:notice] = 'Time window deleted successfully.'
      redirect_to admin_time_windows_path
    end

    private

    def set_time_window
      @time_window = TimeWindow.find(params[:id])
    end

    def time_window_params
      params.require(:time_window).permit(:label, :start_time, :end_time)
    end
  end
end

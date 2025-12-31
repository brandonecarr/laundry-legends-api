module Admin
  class OrdersController < BaseController
    before_action :set_order, only: [:show, :edit, :update, :update_status, :send_notification]

    def index
      @orders = Order.includes(:user, :address, :pickup_time_window, :delivery_time_window)
                     .order(created_at: :desc)

      # Filters
      @orders = @orders.where(status: params[:status]) if params[:status].present?
      @orders = @orders.where(order_type: params[:order_type]) if params[:order_type].present?

      if params[:date_from].present?
        @orders = @orders.where('pickup_date >= ?', params[:date_from])
      end

      if params[:date_to].present?
        @orders = @orders.where('pickup_date <= ?', params[:date_to])
      end

      if params[:search].present?
        search_term = "%#{params[:search].downcase}%"
        @orders = @orders.joins(:user).where(
          'LOWER(users.email) LIKE ? OR LOWER(users.first_name) LIKE ? OR LOWER(users.last_name) LIKE ? OR CAST(orders.order_number AS TEXT) LIKE ?',
          search_term, search_term, search_term, "%#{params[:search]}%"
        )
      end

      @orders = @orders.page(params[:page]).per(50)
    end

    def show
      @timeline_events = @order.timeline_events.order(timestamp: :asc)
      @issue = @order.issue
    end

    def edit
    end

    def update
      if @order.update(order_params)
        flash[:notice] = 'Order updated successfully.'
        redirect_to admin_order_path(@order)
      else
        flash.now[:alert] = 'Failed to update order.'
        render :edit, status: :unprocessable_entity
      end
    end

    def update_status
      new_status = params[:status]
      old_status = @order.status

      if Order.statuses.keys.include?(new_status)
        @order.update(status: new_status)

        # Record actual times based on status
        case new_status
        when 'picked_up'
          @order.update(pickup_actual_time: Time.current)
        when 'delivered'
          @order.update(delivery_actual_time: Time.current)
        end

        # Create timeline event
        OrderTimelineEvent.create!(
          order: @order,
          event_type: status_to_event_type(new_status),
          timestamp: Time.current,
          created_by: current_admin_user
        )

        # Audit log for status change
        AuditLog.log(
          action: 'order_status_changed',
          user: current_admin_user,
          resource: @order,
          metadata: { old_status: old_status, new_status: new_status },
          request: request
        )

        # Auto-send notification if requested
        if params[:send_notification] == '1'
          notification_type = status_to_notification_type(new_status)
          if notification_type
            SendNotificationJob.perform_later(
              user_id: @order.user_id,
              notification_type: notification_type,
              order_id: @order.id,
              channels: [:push, :sms]
            )
            flash[:notice] = "Order status updated to #{new_status.humanize} and notification sent."
          else
            flash[:notice] = "Order status updated to #{new_status.humanize}."
          end
        else
          flash[:notice] = "Order status updated to #{new_status.humanize}."
        end
      else
        flash[:alert] = 'Invalid status.'
      end

      redirect_to admin_order_path(@order)
    end

    def send_notification
      notification_type = params[:notification_type]&.to_sym
      valid_types = NotificationService::NOTIFICATION_TEMPLATES.keys

      unless valid_types.include?(notification_type)
        flash[:alert] = 'Invalid notification type.'
        redirect_to admin_order_path(@order) and return
      end

      # Queue the notification job
      SendNotificationJob.perform_later(
        user_id: @order.user_id,
        notification_type: notification_type.to_s,
        order_id: @order.id,
        channels: [:push, :sms]
      )

      # Audit log for notification sent
      AuditLog.log(
        action: 'notification_sent',
        user: current_admin_user,
        resource: @order,
        metadata: { notification_type: notification_type.to_s },
        request: request
      )

      flash[:notice] = "Notification '#{notification_type.to_s.humanize}' queued for delivery."
      redirect_to admin_order_path(@order)
    end

    private

    def set_order
      @order = Order.find(params[:id])
    end

    def order_params
      params.require(:order).permit(
        :pickup_date, :pickup_time_window_id,
        :delivery_date, :delivery_time_window_id,
        :bag_count, :special_instructions,
        :subtotal_cents, :tax_cents, :total_cents
      )
    end

    def status_to_event_type(status)
      case status
      when 'picked_up' then 'pickup_confirmed'
      when 'in_cleaning' then 'in_cleaning'
      when 'quality_check' then 'quality_check'
      when 'out_for_delivery' then 'out_for_delivery'
      when 'delivered' then 'delivered'
      else 'pickup_confirmed'
      end
    end

    def status_to_notification_type(status)
      {
        'on_way_to_pickup' => 'on_way_pickup',
        'picked_up' => 'picked_up',
        'in_cleaning' => 'started_cleaning',
        'quality_check' => 'cleaning_complete',
        'out_for_delivery' => 'out_for_delivery',
        'delivered' => 'delivered'
      }[status]
    end
  end
end

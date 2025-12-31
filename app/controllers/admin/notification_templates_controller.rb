module Admin
  class NotificationTemplatesController < BaseController
    def index
      # Placeholder - will use NotificationTemplate model later
      @templates = [
        { key: 'on_way_pickup', title: 'On Way to Pickup', push_body: "Hi {customer_name}! We're on our way to pick up your laundry (Order #{'{order_number}'}). See you soon!" },
        { key: 'picked_up', title: 'Picked Up', push_body: "Your laundry has been picked up! We counted {bag_count} bags. It's now heading to our facility for cleaning." },
        { key: 'started_cleaning', title: 'Started Cleaning', push_body: "Good news! We've started cleaning your laundry (Order #{'{order_number}'}). We'll take great care of your items!" },
        { key: 'cleaning_complete', title: 'Cleaning Complete', push_body: "Your laundry is clean and fresh! We're now doing quality checks and packing everything up." },
        { key: 'out_for_delivery', title: 'Out for Delivery', push_body: "We're on our way with your clean laundry! Estimated arrival: {estimated_time}." },
        { key: 'delivered', title: 'Delivered', push_body: "Your laundry has been delivered! Thanks for choosing Laundry Legends. Enjoy your fresh, clean clothes!" }
      ]
    end

    def edit
      @template = { key: params[:id], title: 'Sample Template', push_body: 'Sample body', sms_body: 'Sample SMS' }
    end

    def update
      flash[:notice] = 'Template updated successfully.'
      redirect_to admin_notification_templates_path
    end
  end
end

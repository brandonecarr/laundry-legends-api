module AdminHelper
  def order_status_badge_class(status)
    case status.to_s
    when 'scheduled'
      'bg-yellow-100 text-yellow-800'
    when 'picked_up'
      'bg-blue-100 text-blue-800'
    when 'in_cleaning'
      'bg-indigo-100 text-indigo-800'
    when 'quality_check'
      'bg-purple-100 text-purple-800'
    when 'out_for_delivery'
      'bg-cyan-100 text-cyan-800'
    when 'delivered'
      'bg-green-100 text-green-800'
    when 'canceled'
      'bg-red-100 text-red-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  def issue_type_badge_class(issue_type)
    case issue_type.to_s
    when 'missing_item'
      'bg-red-100 text-red-800'
    when 'damaged'
      'bg-orange-100 text-orange-800'
    when 'not_clean'
      'bg-yellow-100 text-yellow-800'
    when 'wrong_items'
      'bg-purple-100 text-purple-800'
    when 'other'
      'bg-gray-100 text-gray-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  def issue_status_badge_class(status)
    case status.to_s
    when 'submitted'
      'bg-yellow-100 text-yellow-800'
    when 'under_review'
      'bg-blue-100 text-blue-800'
    when 'resolved'
      'bg-green-100 text-green-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  def subscription_status_badge_class(status)
    case status.to_s
    when 'active'
      'bg-green-100 text-green-800'
    when 'paused'
      'bg-yellow-100 text-yellow-800'
    when 'canceled'
      'bg-red-100 text-red-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  def get_next_statuses(current_status)
    status_flow = {
      'scheduled' => ['picked_up', 'canceled'],
      'picked_up' => ['in_cleaning'],
      'in_cleaning' => ['quality_check'],
      'quality_check' => ['out_for_delivery'],
      'out_for_delivery' => ['delivered'],
      'delivered' => [],
      'canceled' => []
    }
    status_flow[current_status.to_s] || []
  end

  def action_badge_class(action)
    case action.to_s
    when 'login', 'admin_login'
      'bg-green-100 text-green-800'
    when 'logout', 'admin_logout'
      'bg-gray-100 text-gray-800'
    when 'order_created'
      'bg-blue-100 text-blue-800'
    when 'order_updated', 'order_status_changed'
      'bg-indigo-100 text-indigo-800'
    when 'order_canceled'
      'bg-red-100 text-red-800'
    when 'customer_updated'
      'bg-cyan-100 text-cyan-800'
    when 'issue_created'
      'bg-orange-100 text-orange-800'
    when 'issue_updated', 'issue_resolved'
      'bg-yellow-100 text-yellow-800'
    when 'subscription_created', 'subscription_updated'
      'bg-purple-100 text-purple-800'
    when 'subscription_canceled'
      'bg-red-100 text-red-800'
    when 'notification_sent'
      'bg-teal-100 text-teal-800'
    when 'settings_updated'
      'bg-pink-100 text-pink-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end
end

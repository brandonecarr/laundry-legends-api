# db/seeds.rb

puts "🌱 Seeding database..."

# Clean existing data (be careful in production!)
[Notification, OrderIssue, OrderTimelineEvent, Order, PaymentMethod,
 Subscription, SubscriptionPlan, LaundryPreference, Address, TimeWindow, User].each(&:destroy_all)

puts "✅ Cleaned existing data"

# Create Time Windows
time_windows = [
  { label: "8:00 AM – 10:00 AM", start_time: "08:00", end_time: "10:00" },
  { label: "10:00 AM – 12:00 PM", start_time: "10:00", end_time: "12:00" },
  { label: "12:00 PM – 2:00 PM", start_time: "12:00", end_time: "14:00" },
  { label: "2:00 PM – 4:00 PM", start_time: "14:00", end_time: "16:00" },
  { label: "4:00 PM – 6:00 PM", start_time: "16:00", end_time: "18:00" }
]

time_windows.each do |tw|
  TimeWindow.create!(tw)
end

puts "✅ Created #{TimeWindow.count} time windows"

# Create Subscription Plans
plans = [
  {
    name: "Basic",
    bags_per_month: 2,
    price_cents: 7900,
    description: "Perfect for individuals. 2 bags per month.",
    is_active: true
  },
  {
    name: "Premium",
    bags_per_month: 4,
    price_cents: 12900,
    description: "Great for families. 4 bags per month.",
    is_active: true
  },
  {
    name: "Elite",
    bags_per_month: 8,
    price_cents: 21900,
    description: "For busy households. 8 bags per month.",
    is_active: true
  }
]

plans.each do |plan|
  SubscriptionPlan.create!(plan)
end

puts "✅ Created #{SubscriptionPlan.count} subscription plans"

# Create Test Users
test_user = User.create!(
  email: "test@laundrylegends.com",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Test",
  last_name: "User",
  phone: "+1234567890",
  role: :customer
)

admin_user = User.create!(
  email: "admin@laundrylegends.com",
  password: "admin123",
  password_confirmation: "admin123",
  first_name: "Admin",
  last_name: "User",
  role: :admin
)

puts "✅ Created test users:"
puts "   Customer: test@laundrylegends.com / password123"
puts "   Admin: admin@laundrylegends.com / admin123"

# Create Address for test user
address = Address.create!(
  user: test_user,
  label: "Home",
  street_address: "123 Main St",
  unit: "Apt 4B",
  city: "San Francisco",
  state: "CA",
  zip_code: "94102",
  delivery_instructions: "Leave at front door",
  is_default: true
)

puts "✅ Created address for test user"

# Laundry Preference is auto-created via User callback
puts "✅ Laundry preferences auto-created"

# Create Subscription for test user
subscription = Subscription.create!(
  user: test_user,
  subscription_plan: SubscriptionPlan.find_by(name: "Premium"),
  status: :active,
  bags_used_this_period: 2,
  current_period_start: Date.today,
  current_period_end: Date.today + 30.days,
  auto_recurring: true,
  recurring_day: 4, # Thursday
  recurring_time_window_id: TimeWindow.first.id
)

puts "✅ Created subscription for test user"

# Create a test order
order = Order.create!(
  user: test_user,
  address: address,
  order_number: 1001,
  status: :in_cleaning,
  order_type: :subscription,
  pickup_date: Date.today - 2.days,
  pickup_time_window_id: TimeWindow.first.id,
  delivery_date: Date.today + 1.day,
  delivery_time_window_id: TimeWindow.second.id,
  pickup_actual_time: (Date.today - 2.days).to_time + 10.hours,
  bag_count: 2,
  subtotal_cents: 4000,
  tax_cents: 320,
  total_cents: 4320,
  laundry_preferences_snapshot: test_user.laundry_preference.as_json
)

puts "✅ Created test order ##{order.order_number}"

# Create timeline events for the order
[
  { event_type: :pickup_confirmed, timestamp: (Date.today - 2.days).to_time + 10.hours },
  { event_type: :in_cleaning, timestamp: (Date.today - 1.day).to_time + 14.hours }
].each do |event|
  OrderTimelineEvent.create!(
    order: order,
    event_type: event[:event_type],
    timestamp: event[:timestamp]
  )
end

puts "✅ Created timeline events for test order"

puts "\n🎉 Seeding complete!"
puts "\n📊 Database Summary:"
puts "   Users: #{User.count}"
puts "   Addresses: #{Address.count}"
puts "   Subscription Plans: #{SubscriptionPlan.count}"
puts "   Subscriptions: #{Subscription.count}"
puts "   Time Windows: #{TimeWindow.count}"
puts "   Orders: #{Order.count}"
puts "   Timeline Events: #{OrderTimelineEvent.count}"
puts "🌱 Seeding database..."

# ========================================
# TIME WINDOWS
# ========================================
puts "Creating time windows..."

time_windows_data = [
  { label: '8:00 AM – 10:00 AM', start_time: '08:00', end_time: '10:00', is_active: true },
  { label: '10:00 AM – 12:00 PM', start_time: '10:00', end_time: '12:00', is_active: true },
  { label: '12:00 PM – 2:00 PM', start_time: '12:00', end_time: '14:00', is_active: true },
  { label: '2:00 PM – 4:00 PM', start_time: '14:00', end_time: '16:00', is_active: true },
  { label: '4:00 PM – 6:00 PM', start_time: '16:00', end_time: '18:00', is_active: true }
]

time_windows_data.each do |tw_data|
  TimeWindow.find_or_create_by!(label: tw_data[:label]) do |tw|
    tw.start_time = tw_data[:start_time]
    tw.end_time = tw_data[:end_time]
    tw.is_active = tw_data[:is_active]
  end
end

puts "✅ Created #{TimeWindow.count} time windows"

# ========================================
# SUBSCRIPTION PLANS
# ========================================
puts "Creating subscription plans..."

plans_data = [
  {
    name: 'Basic',
    bags_per_month: 2,
    price_cents: 7900, # $79
    description: '2 bags per month - Perfect for individuals or couples',
    is_active: true
  },
  {
    name: 'Premium',
    bags_per_month: 4,
    price_cents: 12900, # $129
    description: '4 bags per month - Great for small families',
    is_active: true
  },
  {
    name: 'Elite',
    bags_per_month: 8,
    price_cents: 21900, # $219
    description: '8 bags per month - Best for large families',
    is_active: true
  }
]

plans_data.each do |plan_data|
  SubscriptionPlan.find_or_create_by!(name: plan_data[:name]) do |plan|
    plan.bags_per_month = plan_data[:bags_per_month]
    plan.price_cents = plan_data[:price_cents]
    plan.description = plan_data[:description]
    plan.is_active = plan_data[:is_active]
  end
end

puts "✅ Created #{SubscriptionPlan.count} subscription plans"

# ========================================
# TEST USERS
# ========================================
puts "Creating test users..."

# Customer with subscription
test_user = User.find_or_create_by!(email: 'test@laundrylegends.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.first_name = 'Test'
  user.last_name = 'User'
  user.phone = '+1234567890'
  user.role = :customer
end

# Give test user a subscription
unless test_user.subscription
  premium_plan = SubscriptionPlan.find_by(name: 'Premium')
  Subscription.create!(
    user: test_user,
    subscription_plan: premium_plan,
    status: :active,
    bags_used_this_period: 0,
    current_period_start: Date.today,
    current_period_end: Date.today + 1.month,
    auto_recurring: true
  )
  puts "✅ Created subscription for test user"
end

# Create default address for test user
unless test_user.addresses.exists?
  test_user.addresses.create!(
    label: 'Home',
    street_address: '123 Main Street',
    unit: 'Apt 4B',
    city: 'San Francisco',
    state: 'CA',
    zip_code: '94102',
    delivery_instructions: 'Leave at front door',
    is_default: true
  )
  puts "✅ Created address for test user"
end

# Admin user
User.find_or_create_by!(email: 'admin@laundrylegends.com') do |user|
  user.password = 'admin123'
  user.password_confirmation = 'admin123'
  user.first_name = 'Admin'
  user.last_name = 'User'
  user.phone = '+1234567891'
  user.role = :admin
end

puts "✅ Created test users"

# ========================================
# SUMMARY
# ========================================
puts "\n🎉 Seeding complete!"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts "📊 Database Summary:"
puts "   Users: #{User.count}"
puts "   Time Windows: #{TimeWindow.count}"
puts "   Subscription Plans: #{SubscriptionPlan.count}"
puts "   Subscriptions: #{Subscription.count}"
puts "   Addresses: #{Address.count}"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts "\n🔐 Test Credentials:"
puts "   Customer: test@laundrylegends.com / password123"
puts "   Admin: admin@laundrylegends.com / admin123"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

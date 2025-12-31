# config/initializers/stripe.rb

Stripe.api_key = ENV['STRIPE_SECRET_KEY']

# Optional: Configure for specific API version
# Stripe.api_version = '2023-10-16'

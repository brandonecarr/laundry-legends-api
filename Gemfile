# Gemfile

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"  # ← Fixed to match your Ruby version

# Core Rails
gem "rails", "~> 7.1.0"
gem "pg", "~> 1.1"
gem "puma", "~> 6.0"

# Authentication
gem "bcrypt", "~> 3.1.7"
gem "jwt"

# Background Jobs
gem "sidekiq"
gem "redis", "~> 5.0"

# Payments
gem "stripe"

# Notifications
gem "sendgrid-ruby"
gem "twilio-ruby"

# CORS (only once!)
gem "rack-cors"

# Pagination
gem "kaminari"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Development & Testing
group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  # Add development-only gems here if needed
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install
bundle exec rails db:migrate
bundle exec rails assets:precompile

# Create admin user if environment variables are set
if [ -n "$ADMIN_EMAIL" ] && [ -n "$ADMIN_PASSWORD" ]; then
  bundle exec rails runner "
    unless User.exists?(email: ENV['ADMIN_EMAIL'])
      User.create!(
        email: ENV['ADMIN_EMAIL'],
        password: ENV['ADMIN_PASSWORD'],
        first_name: ENV['ADMIN_FIRST_NAME'] || 'Admin',
        last_name: ENV['ADMIN_LAST_NAME'] || 'User',
        role: :admin
      )
      puts 'Admin user created!'
    else
      user = User.find_by(email: ENV['ADMIN_EMAIL'])
      user.update!(role: :admin) unless user.admin?
      puts 'User already exists, ensured admin role.'
    end
  "
fi

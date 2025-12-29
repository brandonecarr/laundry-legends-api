# config/initializers/cors.rb

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In development, allow localhost
    origins 'localhost:3000', '127.0.0.1:3000'
    
    # In production, use your actual domain
    # origins 'laundrylegends.com', 'www.laundrylegends.com'

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end

# Kracken Engine

Rails Engine for use with the Radius Networks Account Server.


# Install

## 1. Add to the gem file

    gem "omniauth-radius-rails", require: 'kracken', git: 'https://github.com/RadiusNetworks/omniauth-radius-rails.git'


## 2. Create an initializer

In `config/initializers/kraken.rb`:

```ruby
Kracken.setup do |config|
  config.app_id = ENV['OAUTH_APP_ID']
  config.app_secret = ENV['OAUTH_APP_SECRET']
end
```

You can also set `config.provider_url` if you want to override the location of the account server.

## 3. Add routes

In `config/routes.rb`:

```ruby
mount Kracken::Engine => 'auth'
```

## 4. Have a user model

This engine will expect a top level `User` class, and expects it to respond to the following methods:

### `User#id`

Used to put the `user_id` into the session if your controller includes the Kracken Authenticatable mixin.

### `User#find`

Takes one parameter, which is the `user_id`, this is going to be the same value we collected from `User#id` and stored in the session. Used to fetch the current user in the controller.

### User.find_or_create_from_auth_hash

Accepts one parameter which is a hash received from the OAuth server. It will be look something like this:

```ruby
{"provider"=>"radius",
 "uid"=>"1",
 "credentials"=>
  {"token"=>"IAMATOKEN",
   "refresh_token"=>"IAMATOKEN",
   "expires_at"=>1377616922,
   "expires"=>true},
 "extra"=>
  {"raw_info"=>
    {"provider"=>"radius",
     "id"=>"3",
     "attributes"=>
      {"user"=>
        {"admin"=>true,
         "company"=>nil,
         "country"=>"United States",
         "created_at"=>"2000-01-00T00:00:00Z",
         "email"=>"joe@example.com",
         "expiration_date"=>"2000-01-00",
         "first_name"=>"Joe",
         "id"=>1,
         "last_name"=>"Cool",
         "status"=>"Active",
         "updated_at"=>"2000-01-00T00:00:00Z",
         "uid"=>1,
         "accounts"=>[{"id"=>1, "name"=>"Radius Networks", "uid"=>1}]}}}}}
```

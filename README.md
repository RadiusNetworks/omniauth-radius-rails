# Kracken Rails Engine

Rails Engine for use with the Radius Networks Account Server, which is also known as Kracken. Basically this will configure rails to consume oauth provided from Kracken.

[![Build Status](https://travis-ci.org/RadiusNetworks/omniauth-radius-rails.svg)](https://travis-ci.org/RadiusNetworks/omniauth-radius-rails)

# Usage

## A note about the name

the repo is called `omniauth-radius-rails` which is mostly to be an indicator of what this repo does, and to be below the radar on our github page. The gem itself is called `kracken`, and so it's top level namespace is `Kracken`.

## Control access on a controller

You can restrict access to one of you controllers by adding a before filter.

```ruby
before_filter :authenticate_user!
```

To get access to those helpers you will want to mixin the Authenticatable module. Normally this is done in your apps `ApplicationController`

```ruby
include Kracken::Controllers::Authenticatable
```

## Helpers

Authenticatable includes helpers such as

* `sign_out_path`
* `sign_up_path`
* `sign_in_path`
* `current_user`

# Install

### 1. Add to the gem file

    gem 'kracken', github: 'RadiusNetworks/omniauth-radius-rails'


### 2. Create an initializer

In `config/initializers/kraken.rb`:

```ruby
Kracken.setup do |config|
  config.app_id = ENV['OAUTH_APP_ID']
  config.app_secret = ENV['OAUTH_APP_SECRET']
end
```

You can also set `ENV['RADIUS_OAUTH_PROVIDER_URL']` if you want to override the location of the account server.

### 3. Add routes

In `config/routes.rb`:

```ruby
mount Kracken::Engine => 'auth'
```

### 4. Have a user model

This engine will expect a top level `User` class, and expects it to respond to the following methods:

#### `User#id`

Used to put the `user_id` into the session if your controller includes the Kracken Authenticatable mixin.

#### `User#find`

Takes one parameter, which is the `user_id`, this is going to be the same value we collected from `User#id` and stored in the session. Used to fetch the current user in the controller.

#### User.find_or_create_from_auth_hash

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

# Additional API

## Login

Alows direct login to the Kracken Server. This will also call the user model configured in the initializer with `find_or_create_from_auth_hash` then return that user model.

```
user = Kracken::Login.new(email, password).login_and_create_user!
```

## Update with OAuth Token

The OAuth exchange will create a `refresh_token` which can be used to request and update to the `auth_hash`. Typical [usage](https://github.com/RadiusNetworks/gamera/blob/sdk-config-kit-options/app/controllers/application_controller.rb):

```
updater = Kracken::Updater.new current_user.credentials.token
updater.refresh_with_oauth!
current_user.reload
```



# Kracken Rails Engine

Rails Engine for use with the Radius Networks Account Server, which is also known as Kracken. Basically this will configure rails to consume oauth provided from Kracken.

[![Build Status](https://travis-ci.org/RadiusNetworks/omniauth-radius-rails.svg)](https://travis-ci.org/RadiusNetworks/omniauth-radius-rails)

## A note about the name

The repo is called `omniauth-radius-rails` which is mostly to be an indicator of what this repo does, and to be below the radar on our github page. The gem itself is called `kracken`, and so it's top level namespace is `Kracken`.

# Usage

This Rails engine will do a number of things around authentication, users and teams. But is specifically designed to be agnostic data models and the like. The primary use is to enable an app to to login via OAuth with Kracken. This is normally accomplished with a few controller mix-ins and a mounted engine to handle the callbacks.


In general there are two main mix-ins, one for normal web use and another for creating a public API.


## Controllers

Two main types of controller mix-ins. Web Controllers for normal browser based web pages and API Controllers for API access and common helpers.

### Authenticatable

To authenticate users using the session and provide a number of HTML helpers, use the `Authenticatable` mix-in.

Filters

* `authenticate_user!` Set the current user from the browser session.

Helpers

* `current_user`
* `sign_out_path`
* `sign_up_path`
* `sign_in_path`


#### Token Authenticatable

To authenticate via a API token use the `TokenAuthenticatable` mix-in.

Filters

* `authenticate_user_with_token!` Set the current user from the token header.

Helpers

* `current_user`

Skips `verify_authenticity_token` since it is a

#### JSON API Compatible

Configure a controller to be a JSON api with sensible defaults

Filters

* Skip `verify_authenticity_token` since we are not posting form data from a browser
* Run `munge_header_auth_token` to split a list of IDs by commas

It will also set `rescue_from` handlers to render errors as JSON responses.

Helpers

* `render_json_error` create standard json error response format and render the request


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

### 3. Mount Engine

In `config/routes.rb`:

```ruby
mount Kracken::Engine => 'auth'
```

### 4. User Model

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
 "info"=>
  {"first_name"=>"admin",
   "last_name"=>"admin",
   "email"=>"admin@radiusnetworks.com",
   "uid"=>1,
   "confirmed"=>true,
   "teams"=>[{"id"=>1, "name"=>"Spiffy", "uid"=>1}],
   "admin"=>true,
   "subscription_level"=>"pro"},
 "credentials"=>
  {"token"=>"c3dcf656bcd54d757172d0a22a6d101d",
   "refresh_token"=>"7ac5efecc749749bcf3ce6ee6f878178",
   "expires_at"=>"2015-03-12T14:57:53.523Z",
   "expires"=>true},
 "extra"=>
  {"raw_info"=>
    {"provider"=>"radius",
     "id"=>"1",
     "uid"=>"1",
     "info"=>
      {"id"=>1,
       "email"=>"admin@radiusnetworks.com",
       "admin"=>true,
       "first_name"=>"admin",
       "last_name"=>"admin",
       "status"=>"Active",
       "expiration_date"=>"2016-02-12",
       "created_at"=>"2015-02-12T14:57:53.523Z",
       "updated_at"=>"2015-03-10T17:40:35.621Z",
       "company"=>nil,
       "country"=>"United States",
       "terms_of_service"=>true,
       "initial_service_code"=>nil,
       "initial_plan_code"=>nil,
       "customer_id"=>nil,
       "subscription_id"=>2,
       "uid"=>1,
       "confirmed"=>true,
       "subscription_level"=>"pro",
       "teams"=>[{"id"=>1, "name"=>"Spiffy", "uid"=>1}]}}}}
```

### 5. Configure App Controller

Include the mix-in in your Application Controller:

```
include Kracken::Controllers::Authenticatable
```

Note that this will call the `authenticate_user!` before action by default, so if you want to provide access to a page with out authentication that needs to be skipped:

```
skip_filter :authenticate_user!, except: [:secure_action]
```

# Beyond OAuth

## Proxy Login

Allows direct login to the Kracken Server. Normally used for logging in a user
via a mobile app.  This will also call the user model configured in the
initializer with `find_or_create_from_auth_hash` then return that user model.

```
user = Kracken::Authenticator.user_with_credentials(email, password)
```

This requires the `app_id` and `app_secret` be set in the initializer.

## Update with OAuth Token

The OAuth exchange will create a `refresh_token` which can be used to request and update to the `auth_hash`. Typical [usage](https://github.com/RadiusNetworks/gamera/blob/sdk-config-kit-options/app/controllers/application_controller.rb):

```
Kracken::Authenticator.user_with_token(current_user.credentials.token)
# Might want to reload the current_user model
current_user.reload
```



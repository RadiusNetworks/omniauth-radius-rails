# Kracken Engine

Rails Engine for use with the Radius Networks Account Server.


# Install

Add to the gem file

Expects a user model

this engine will expect a top level `User` class, and expects it to respond to the following

### `User#id`

Used to put the `user_id` into the session if your controller includes the Kracken Authenticatable mixin.

### `User#find`

Takes one parameter, which is the `user_id`, this is going to be the same value we collected from `User#id` and stored in the session. Used to fetch the current user in the controller.

### User.find_or_create_from_auth_hash

Accepts one parameter which is a hash received from the OAuth server. It will be look something like this:

```ruby
{"provider"=>"radius",
 "uid"=>"3",
 "info"=>{"name"=>nil, "email"=>nil},
 "credentials"=>
  {"token"=>"01f8f2f50913eb24ad685385fc6ea289",
   "refresh_token"=>"af081784e70f42bef744185742765a72",
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
         "created_at"=>"2012-08-30T18:14:10Z",
         "email"=>"chris@radiusnetworks.com",
         "expiration_date"=>"2013-08-30",
         "first_name"=>"Christopher",
         "id"=>3,
         "last_name"=>"Sexton",
         "status"=>"Active",
         "updated_at"=>"2013-08-27T14:52:03Z",
         "uid"=>3,
         "accounts"=>[{"id"=>1, "name"=>"Radius Networks", "uid"=>1}]}}}}}
```

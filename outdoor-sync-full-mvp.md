# Complete OutdoorSync App MVP Plan (Rails 8)

## App Concept

OutdoorSync is an app that connects enthusiasts of various outdoor activities, including surfing, hiking, snowboarding, skiing, climbing, camping, via ferrata, and etc. Users can find activity partners, plan trips, and chat in real-time.

## Tech Stack

- Framework: Ruby on Rails 8
- Database: SQLite
- Real-time: Action Cable (built-in)
- Background Jobs: Active Job with Solid Queue
- Caching: Rails built-in caching with Solid Cache
- Web Server: Thruster
- Authentication: Rails 8 built-in authentication system
- Testing: Minitest (Rails 8 built-in)
- Deployment: Kamal
- Hosting: Ubuntu Server

## Core Features

1. User Authentication (using Rails 8 built-in system)
2. User Profiles with activity preferences
3. Activity Event Broadcasting
4. Real-time Messaging
5. Location Services

## Database Schema

1. Users Table (managed by Rails 8 authentication)

   ```ruby
   # db/migrate/YYYYMMDDHHMMSS_create_users.rb
   class CreateUsers < ActiveRecord::Migration[8.0]
     def change
       create_table :users do |t|
         t.string :email_address, null: false, index: { unique: true }
         t.string :password_digest, null: false
         t.string :name
         t.text :location
         t.json :activity_preferences
         t.json :experience_levels
         t.string :profile_picture

         t.timestamps
       end
     end
   end
   ```

2. Sessions Table (for Rails 8 authentication)

   ```ruby
   # db/migrate/YYYYMMDDHHMMSS_create_sessions.rb
   class CreateSessions < ActiveRecord::Migration[8.0]
     def change
       create_table :sessions do |t|
         t.references :user, null: false, foreign_key: true
         t.string :ip_address
         t.string :user_agent

         t.timestamps
       end
     end
   end
   ```

3. Activities Table

   ```ruby
   # db/migrate/YYYYMMDDHHMMSS_create_activities.rb
   class CreateActivities < ActiveRecord::Migration[8.0]
     def change
       create_table :activities do |t|
         t.string :name, null: false
         t.string :category, null: false
         t.timestamps
       end
     end
   end
   ```

4. Events Table

   ```ruby
   # db/migrate/YYYYMMDDHHMMSS_create_events.rb
   class CreateEvents < ActiveRecord::Migration[8.0]
     def change
       create_table :events do |t|
         t.references :user, foreign_key: true
         t.references :activity, foreign_key: true
         t.text :location
         t.string :location_name
         t.datetime :start_time
         t.string :status
         t.text :description
         t.integer :max_participants
         t.timestamps
       end
     end
   end
   ```

5. Participants Table

   ```ruby
   # db/migrate/YYYYMMDDHHMMSS_create_participants.rb
   class CreateParticipants < ActiveRecord::Migration[8.0]
     def change
       create_table :participants do |t|
         t.references :user, foreign_key: true
         t.references :event, foreign_key: true
         t.timestamps
       end
     end
   end
   ```

6. Messages Table

   ```ruby
   # db/migrate/YYYYMMDDHHMMSS_create_messages.rb
   class CreateMessages < ActiveRecord::Migration[8.0]
     def change
       create_table :messages do |t|
         t.references :user, foreign_key: true
         t.references :chat_room, polymorphic: true
         t.text :content
         t.timestamps
       end
     end
   end
   ```

7. ChatRooms Table

   ```ruby
   # db/migrate/YYYYMMDDHHMMSS_create_chat_rooms.rb
   class CreateChatRooms < ActiveRecord::Migration[8.0]
     def change
       create_table :chat_rooms do |t|
         t.string :name
         t.references :event, foreign_key: true, null: true
         t.timestamps
       end
     end
   end
   ```

## Models

1. User Model

   ```ruby
   # app/models/user.rb
   class User < ApplicationRecord
     has_secure_password
     has_many :events
     has_many :participants
     has_many :messages

     validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
     validates :password, length: { minimum: 8 }, if: -> { new_record? || changes[:password_digest] }
     validates :name, presence: true
   end
   ```

2. Session Model

   ```ruby
   # app/models/session.rb
   class Session < ApplicationRecord
     belongs_to :user
   end
   ```

3. Activity Model

   ```ruby
   # app/models/activity.rb
   class Activity < ApplicationRecord
     has_many :events
     validates :name, presence: true
     validates :category, presence: true
   end
   ```

4. Event Model

   ```ruby
   # app/models/event.rb
   class Event < ApplicationRecord
     belongs_to :user
     belongs_to :activity
     has_many :participants
     has_one :chat_room

     validates :location, presence: true
     validates :start_time, presence: true
     validates :max_participants, presence: true, numericality: { greater_than: 0 }
   end
   ```

5. Participant Model

   ```ruby
   # app/models/participant.rb
   class Participant < ApplicationRecord
     belongs_to :user
     belongs_to :event
   end
   ```

6. Message Model

   ```ruby
   # app/models/message.rb
   class Message < ApplicationRecord
     belongs_to :user
     belongs_to :chat_room

     validates :content, presence: true

     after_create_commit { broadcast_append_to chat_room }
   end
   ```

7. ChatRoom Model

   ```ruby
   # app/models/chat_room.rb
   class ChatRoom < ApplicationRecord
     belongs_to :event, optional: true
     has_many :messages
   end
   ```

## Controllers

1. Application Controller

   ```ruby
   # app/controllers/application_controller.rb
   class ApplicationController < ActionController::Base
     include Authentication
   end
   ```

2. Authentication Concern

   ```ruby
   # app/controllers/concerns/authentication.rb
   module Authentication
     extend ActiveSupport::Concern

     included do
       before_action :authenticate
     end

     private
       def authenticate
         if authenticated_user = User.find_by(id: session[:user_id])
           Current.user = authenticated_user
         else
           redirect_to new_session_path
         end
       end

       def login(user)
         Current.user = user
         reset_session
         session[:user_id] = user.id
       end

       def logout
         Current.user = nil
         reset_session
       end
   end
   ```

3. Sessions Controller

   ```ruby
   # app/controllers/sessions_controller.rb
   class SessionsController < ApplicationController
     skip_before_action :authenticate, only: [:new, :create]

     def new
     end

     def create
       user = User.find_by(email_address: params[:email_address])

       if user && user.authenticate(params[:password])
         login user
         redirect_to root_path, notice: "Logged in successfully"
       else
         flash.now[:alert] = "Invalid email or password"
         render :new, status: :unprocessable_entity
       end
     end

     def destroy
       logout
       redirect_to root_path, notice: "Logged out successfully"
     end
   end
   ```

4. Passwords Controller

   ```ruby
   # app/controllers/passwords_controller.rb
   class PasswordsController < ApplicationController
     skip_before_action :authenticate

     def new
     end

     def create
       if user = User.find_by(email_address: params[:email_address])
         PasswordMailer.with(
           user: user,
           token: user.generate_token_for(:password_reset)
         ).reset.deliver_later

         redirect_to new_session_path, notice: "Check your email for reset instructions"
       else
         redirect_to new_password_path, alert: "You can't reset an email that doesn't exist"
       end
     end

     def edit
       @user = User.find_signed(params[:token], purpose: :password_reset)
     rescue ActiveSupport::MessageVerifier::InvalidSignature
       redirect_to new_password_path, alert: "That reset link is invalid"
     end

     def update
       @user = User.find_signed(params[:token], purpose: :password_reset)

       if @user.update(password_params)
         login @user
         redirect_to root_path, notice: "Your password has been reset successfully"
       else
         render :edit, status: :unprocessable_entity
       end
     rescue ActiveSupport::MessageVerifier::InvalidSignature
       redirect_to new_password_path, alert: "That reset link is invalid"
     end

     private
       def password_params
         params.require(:user).permit(:password, :password_confirmation)
       end
   end
   ```

5. Events Controller

   ```ruby
   # app/controllers/events_controller.rb
   class EventsController < ApplicationController
     def index
       @events = Event.all
     end

     def show
       @event = Event.find(params[:id])
     end

     def new
       @event = Event.new
     end

     def create
       @event = Current.user.events.build(event_params)

       if @event.save
         redirect_to @event, notice: 'Event was successfully created.'
       else
         render :new, status: :unprocessable_entity
       end
     end

     private
       def event_params
         params.require(:event).permit(:activity_id, :location, :location_name, :start_time, :description, :max_participants)
       end
   end
   ```

6. ChatRooms Controller

   ```ruby
   # app/controllers/chat_rooms_controller.rb
   class ChatRoomsController < ApplicationController
     def show
       @chat_room = ChatRoom.find(params[:id])
       @message = Message.new
     end
   end
   ```

7. Messages Controller

   ```ruby
   # app/controllers/messages_controller.rb
   class MessagesController < ApplicationController
     def create
       @chat_room = ChatRoom.find(params[:chat_room_id])
       @message = @chat_room.messages.build(message_params)
       @message.user = Current.user

       if @message.save
         head :ok
       else
         render :new, status: :unprocessable_entity
       end
     end

     private
       def message_params
         params.require(:message).permit(:content)
       end
   end
   ```

## Views

Use Turbo (built into Rails 8) for dynamic updates without full page reloads. Here are some key view templates:

1. Application Layout

   ```erb
   <!-- app/views/layouts/application.html.erb -->
   <!DOCTYPE html>
   <html>
     <head>
       <title>OutdoorSync</title>
       <%= csrf_meta_tags %>
       <%= csp_meta_tag %>

       <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
       <%= javascript_importmap_tags %>
     </head>

     <body>
       <%= yield %>
     </body>
   </html>
   ```

2. Events Index

   ```erb
   <!-- app/views/events/index.html.erb -->
   <h1>Outdoor Events</h1>

   <%= turbo_stream_from "events" %>

   <div id="events">
     <%= render @events %>
   </div>

   <%= link_to "New Event", new_event_path %>
   ```

3. Chat Room Show

   ```erb
   <!-- app/views/chat_rooms/show.html.erb -->
   <h1><%= @chat_room.name %></h1>

   <%= turbo_stream_from @chat_room %>

   <div id="messages">
     <%= render @chat_room.messages %>
   </div>

   <%= form_with(model: [@chat_room, @message], local: false) do |f| %>
     <%= f.text_field :content %>
     <%= f.submit "Send" %>
   <% end %>
   ```

## Real-time Chat Implementation

1. Chat Channel

   ```ruby
   # app/channels/chat_channel.rb
   class ChatChannel < ApplicationCable::Channel
     def subscribed
       stream_from "chat_#{params[:room_id]}"
     end
   end
   ```

2. Message Broadcast

   ```ruby
   # app/models/message.rb
   class Message < ApplicationRecord
     after_create_commit { broadcast_append_to "chat_#{chat_room_id}" }
   end
   ```

## Thruster Server Configuration

1. Install Thruster on Ubuntu server

2. Configure Thruster in your Rails application:

   ```ruby
   # config/thruster.rb
   Thruster.configure do |config|
     config.port = 3000
     config.workers = 4
   end
   ```

3. Configure Rails to work with Thruster:
   ```ruby
   # config/environments/production.rb
   config.action_cable.allowed_request_origins = ['https://yourdomain.com']
   ```

## Testing with Minitest

1. User Model Test

   ```ruby
   # test/models/user_test.rb
   require "test_helper"

   class UserTest < ActiveSupport::TestCase
     test "should not save user without email" do
       user = User.new(password: "password123")
       assert_not user.save, "Saved the user without an email"
     end

     test "should not save user with invalid email format" do
       user = User.new(email_address: "invalid_email", password: "password123")
       assert_not user.save, "Saved the user with an invalid email format"
     end

     test "should not save user with short password" do
       user = User.new(email_address: "test@example.com", password: "short")
       assert_not user.save, "Saved the user with a short password"
     end
   end
   ```

2. Sessions Controller Test

   ```ruby
   # test/controllers/sessions_controller_test.rb
   require "test_helper"

   class SessionsControllerTest < ActionDispatch::IntegrationTest
     test "should get new" do
       get new_session_url
       assert_response :success
     end

     test "should create session with valid credentials" do
       user = users(:one)
       post session_url, params: { email_address: user.email_address, password: 'password' }
       assert_redirected_to root_url
       assert_equal user.id, session[:user_id]
     end

     test "should not create session with invalid credentials" do
       post session_url, params: { email_address: 'invalid@example.com', password: 'wrongpassword' }
       assert_response :unprocessable_entity
       assert_nil session[:user_id]
     end

     test "should destroy session" do
       login_as(users(:one))
       delete session_url
       assert_redirected_to root_url
       assert_nil session[:user_id]
     end
   end
   ```

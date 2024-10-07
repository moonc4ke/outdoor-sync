# OutdoorSync App MVP Plan

## App Concept

OutdoorSync is an app that connects enthusiasts of various outdoor activities, including surfing, hiking, snowboarding, skiing, climbing, camping, via ferrata, and etc. Users can find activity partners, plan trips, and chat in real-time.

## Tech Stack

- Framework: Ruby on Rails 8
- Database: SQLite
- Real-time: Solid Cable
- Background Jobs: Solid Queue
- Caching: Solid Cache
- Web Server: Thruster
- Deployment: Kamal
- Hosting: Ubuntu Server

## Core Features

1. User Authentication
2. User Profiles with activity preferences
3. Activity Session Broadcasting
4. Real-time Messaging
5. Location Services

## Database Schema

1. Users Table

   ```ruby
   create_table :users do |t|
     t.string :username, null: false
     t.string :email, null: false
     t.string :password_digest, null: false
     t.string :name
     t.text :location
     t.json :activity_preferences
     t.json :experience_levels
     t.string :profile_picture
     t.timestamps
   end
   ```

2. Activities Table

   ```ruby
   create_table :activities do |t|
     t.string :name, null: false
     t.string :category, null: false
     t.timestamps
   end
   ```

3. Sessions Table

   ```ruby
   create_table :sessions do |t|
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
   ```

4. Participants Table

   ```ruby
   create_table :participants do |t|
     t.references :user, foreign_key: true
     t.references :session, foreign_key: true
     t.timestamps
   end
   ```

5. Messages Table

   ```ruby
   create_table :messages do |t|
     t.references :user, foreign_key: true
     t.references :chat_room, polymorphic: true
     t.text :content
     t.timestamps
   end
   ```

6. ChatRooms Table
   ```ruby
   create_table :chat_rooms do |t|
     t.string :name
     t.references :session, foreign_key: true, null: true
     t.timestamps
   end
   ```

## Key Components

1. Models

   - User, Activity, Session, Participant, Message, ChatRoom

2. Controllers

   - UsersController, ActivitiesController, SessionsController, MessagesController, ChatRoomsController

3. Views

   - Leverage Hotwire for dynamic updates without full page reloads

4. Real-time Chat with Hotwire and Solid Cable

## Real-time Chat Implementation

1. Solid Cable Setup

   ```ruby
   # app/channels/chat_channel.rb
   class ChatChannel < Solid::Cable::Channel
     def subscribed
       stream_from "chat_#{params[:room_id]}"
     end
   end
   ```

2. Broadcast Messages

   ```ruby
   # app/models/message.rb
   class Message < ApplicationRecord
     after_create_commit { broadcast_append_to "chat_#{chat_room_id}" }
   end
   ```

3. Turbo Stream in View

   ```erb
   <%= turbo_stream_from "chat_#{@chat_room.id}" %>
   <div id="messages">
     <%= render @chat_room.messages %>
   </div>
   ```

4. Stimulus Controller for Sending Messages

   ```javascript
   // app/javascript/controllers/chat_controller.js
   import { Controller } from "stimulus";

   export default class extends Controller {
     static targets = ["input"];

     send(event) {
       event.preventDefault();
       this.stimulate("Chat#send", this.inputTarget.value);
       this.inputTarget.value = "";
     }
   }
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
   config.solid_cable.allowed_request_origins = ['https://yourdomain.com']
   ```

## Deployment Steps with Kamal

1. Set up Ubuntu server with Ruby and SQLite
2. Install Thruster server
3. Configure Kamal for deployment

   ```yaml
   # config/deploy.yml
   service: outdoor_connect
   image: your-docker-registry/outdoor_connect
   servers:
     - 123.456.789.10
   env:
     RAILS_ENV: production
     DATABASE_URL: sqlite3:///mnt/data/production.sqlite3
   ```

4. Set up Solid Cable for production
5. Deploy using Kamal:
   ```
   kamal deploy
   ```
6. Start Thruster server:
   ```
   bundle exec thruster
   ```

## Additional Configurations

1. Solid Queue Setup

   ```ruby
   # config/environments/production.rb
   config.active_job.queue_adapter = :solid_queue
   ```

2. Solid Cache Setup
   ```ruby
   # config/environments/production.rb
   config.cache_store = :solid_cache_store
   ```

## Future Enhancements

- Activity-specific features (e.g., wave forecasts for surfing, trail maps for hiking)
- Equipment sharing or rental system
- Integration with weather APIs for activity planning
- Social features like activity logs and achievements

# Webhooks Demo

Pull down the workshop repository
Pull down the repository and switch to the start-here remote branch

    # clone from Github
    git clone git@github.com:pradeepgopireddy/webhooks-rails.git

    # move into directory
    cd webhooks-rails

    # fetch all the upstream branches that include the steps of this workshop
    git fetch --all

    # checkout the start-here branch
    git checkout start-here

    # install dependencies
    bundle install

    # start server
    rails server

You should now have a brand new Rails app up and running. You can verify by visiting http://localhost:3000

This README would normally document whatever steps are necessary to get the application up and running.

Things you may want to cover:

* Ruby version
    RUBY: 2.6.1
    RAILS: 5.0.7.2

* System dependencies


* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)
# Step 1: Setting Up a Controller and Rails Routes
We'll start by creating a controller and an HTTP route to catch the webhook events.
## 1A) Creating a Webhooks Controller
This demo webhooks controller also includes an example of how to send a webhook to your application. You can use this to test your webhook processor.

    rails generate controller WebhooksController


    # app/controllers/webhooks_controller.rb
    class WebhooksController < ApplicationController
  
        # Disable CSRF checks on webhooks because they are not originated from browser
        skip_before_action :verify_authenticity_token, on: [:create]

        # To send a sample webhook locally:
        #  curl -X POST http://localhost:3000/webhooks/github_pull_request 
        #       -H "Content-Type: application/json" 
        #       -d '{ "data": "Sample data", "status": "pending"}'
  
        # POST /webhooks/:source_name
        def create
            @webhook = Webhook.new()
            @webhook.source_name = params[:source_name]
            @webhook.data = payload
            if @webhook.save
                render json: {status: :ok }, status: :ok
            else
                render json: {errors: @webhook.errors}, status: :unprocessable_entity
            end
        end

        # curl -X PUT http://localhost:3000/webhooks/3 
        #       -H "Content-Type: application/json" 
        #       -d '{"type": "customer.updated", "data": "Updated data", "status": "pending"}'

        # PATCH/PUT /webhooks/1
        def update
            @webhook.data = payload
            if @webhook.save
                render json: {status: :ok}, status: :ok
            else
                render json: {errors: @webhook.errors}, status: :unprocessable_entity
            end
        end

        private
        # Use callbacks to share common setup or constraints between actions.
        def set_webhook
            @webhook = Webhook.find(params[:id])
        end

        # Only allow a list of trusted parameters through.
        def webhook_params
            params.permit(:data, :status)
        end

        def payload
            @payload ||= request.body.read
        end
    end
## 1B) Adding Routes for the Webhook Controllers
Finally, we need to add routes for these webhook controllers.

We are going to set up routes to webhook controller. We will only allow the create/update action on these routes.

    # config/routes.rb

    Rails.application.routes.draw do
        resources :webhooks, only: [:create, :update, :index, :show, :destroy]
        # http://localhost:3000/webhooks/github_pull_request
        # http://localhost:3000/webhooks/stripe_request
        post '/webhooks/:source_name', to: 'webhooks#create'
        root 'webhooks#index'
        
        # your other routes here
    end

## 1C) Testing our new routes
We can test our new routes by sending a request to our new webhook routes. We can use curl to send a request to our new webhook routes.

Let's run the server and send a request to our new webhook routes.

This should be successful and return a 200 status code.
    
    curl -X POST 'http://localhost:3000/webhooks/github_request' -H 'Content-Type: application/json' -d '{"data":"Sample Data", "status": "pending"}'

Now that we have our routes set up, we can move on to creating a webhook model.

# Step 2: Creating a Webhook Model
This model(webhook) will be responsible for storing the webhook until a background job can process it.

The reason we want to do this is because we want our controller to respond as fast as possible for heavy traffic (like Amazon prime day sale for example) and we want to store the record in the database to safely store it for retries if the service is having trouble for any reason.

## 2A) Creating the Webhook Model
We can use the Rails generator to create our model.

    rails generate model Webhook source_name:string data:jsonb status:string

We should now have a model file with basic validations and a migration file.

    # app/models/webhook.rb

    class Webhook < ApplicationRecord

        validates :source_name, presence: true
        validates :data, presence: true
    end


    # db/migrate/20230809025933_create_webhooks.rb

    class CreateWebhooks < ActiveRecord::Migration[5.0]
        def change
            create_table :webhooks do |t|
            t.string :source_name
            t.jsonb :data
            t.string :status, default: :pending

            t.timestamps
            end
        end
    end

Now we can run our migration to create the table in the database.

    rails db:migrate

Now that we have a model and a backing table in the database, we can save our webhook to the database.

# Step 3: Creating a Background Worker
Now that we have a record in our database, we need to process it. We don't want to process it in the controller because that would slow down our response time. Instead, we want to process it in a background job.

## 3A) Creating the Background Job
Let's use another Rails generator to create a background job.

In thise case, we are going to use the ActiveJob framework that comes with Rails. This will allow us to easily switch between background job providers like Sidekiq, Resque, DelayedJob, etc.

Let's create a job for our webhook provider

    rails generate job WebhookJob



    # app/jobs/webhook_job.rb

    class WebhookJob < ApplicationJob
        queue_as :default

        def perform(webhook)
            payload = JSON.parse(webhook.data, symbolize_names: true)
            
            # create stripe event object from payload data
            event = Stripe::Event.construct_from(payload)
            case event.type
            when 'customer.updated'
                # handle updated customer event
                webhook.update!(status: :processed)
            else
                webhook.update!(status: :skipped)
            end
        end
    end


# 3B) Updating our Webhook Controllers to enqueue jobs
Now that we have our jobs defined, we need to enqueue them in our webhook controller.

Let's update the webhooks controller to process these webhooks

    # app/controllers/webhooks_controller.rb


    class WebhooksController < ApplicationController
  
        # POST /webhooks/:source_name
        def create
            @webhook = Webhook.new()
            @webhook.source_name = params[:source_name]
            @webhook.data = payload
            if @webhook.save
                # Enqueue database record for processing
                WebhookJob.perform_later(@webhook)
                render json: {status: :ok }, status: :ok
            else
                render json: {errors: @webhook.errors}, status: :unprocessable_entity
            end
        end

        # PATCH/PUT /webhooks/1
        def update
            @webhook.data = payload
            if @webhook.save
                WebhookJob.perform_later(@webhook)
                render json: {status: :ok}, status: :ok
            else
                render json: {errors: @webhook.errors}, status: :unprocessable_entity
            end
        end

        private
       
        def set_webhook
            @webhook = Webhook.find(params[:id])
        end

        def payload
            @payload ||= request.body.read
        end
    end

* Deployment instructions

* ...

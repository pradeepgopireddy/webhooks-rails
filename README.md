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
        before_action :set_webhook, only: %i[ show update destroy ]
  
        # Disable CSRF checks on webhooks because they are not originated from browser
        skip_before_action :verify_authenticity_token, on: [:create]

        # GET /webhooks
        def index
            @webhooks = Webhook.all
        end

        # To send a sample webhook locally:
        #  curl -X POST http://localhost:3000/webhooks/github_pull_request 
        #       -H "Content-Type: application/json" 
        #       -d '{ "data": "Sample data", "status": "pending"}'
  
        # POST /webhooks
        def create
            @webhook = Webhook.new()
            @webhook.source_name = params[:source_name]
            @webhook.data = payload
            if @webhook.save
            WebhookJob.perform_later(@webhook)
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
            WebhookJob.perform_later(@webhook)
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

* Deployment instructions

* ...

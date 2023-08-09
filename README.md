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

* Deployment instructions

* ...

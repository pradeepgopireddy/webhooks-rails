class NotifiersController < ApplicationController
    skip_before_action :verify_authenticity_token, on: [:notify]
    
    def notify
        head :ok
    end
end

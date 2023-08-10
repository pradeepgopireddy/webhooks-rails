class WebhooksController < ApplicationController
  before_action :set_webhook, only: %i[ show update destroy ]
  
  # Disable CSRF checks on webhooks because they are not originated from browser
  skip_before_action :verify_authenticity_token, on: [:create]
  before_action :validate_webhook_authenticity

  # GET /webhooks
  def index
    @webhooks = Webhook.all
  end

  # GET /webhooks/1
  def show
  end

  #  curl -X POST http://localhost:3000/webhooks/github_pull_request -H "Content-Type: application/json"  -H "X-Webhook-Token: YOUR_TOKEN" -d '{ "data": "Sample data", "status": "pending"}'

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

  # curl -X PUT http://localhost:3000/webhooks/3 -H "Content-Type: application/json" -d '{"type": "customer.updated", "data": "Updated data", "status": "pending"}'

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

  # DELETE /webhooks/1 or /webhooks/1.json
  def destroy
    @webhook.destroy

    respond_to do |format|
      format.html { redirect_to webhooks_url, notice: "Webhook was successfully destroyed." }
      format.json { head :no_content }
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

    def validate_webhook_authenticity
      provided_token = request.headers['X-Webhook-Token']
      shared_token = Rails.application.credentials.webhook_key # Store the token in Rails credentials 
  
      head :unauthorized unless provided_token == shared_token
    end

    def notify_third_party_endpoints
      config_endpoints = Rails.configuration.third_party_endpoints
      config_endpoints.each do |endpoint|
        response = HTTParty.post(endpoint, body: { data_item: @webhook.attributes }.to_json, headers: { 'Content-Type' => 'application/json' })
        unless response.successful?
          Rails.logger.error("Failed to notify endpoint #{endpoint}: #{response.code} - #{response.body}")
        end
      end
    end
end

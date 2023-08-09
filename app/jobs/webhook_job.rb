class WebhookJob < ApplicationJob
  queue_as :default

  # ak_2TjGpar3ZuLHCRK96RaGPoTpSZa

  def perform(webhook)
    event = fetch_strip_event(webhook.data)
    begin
      case event.type
      when 'customer.updated'
        # handle updated customer event
        webhook.update!(status: :processed)
      else
        webhook.update!(status: :skipped)
      end
    rescue StandardError => e
      webhook.update!(status: :failed)
    end
  end

  # create stripe event object from payload data
  def fetch_strip_event(webhook_data)
    payload = JSON.parse(webhook_data, symbolize_names: true)
    Stripe::Event.construct_from(payload)
  end
end

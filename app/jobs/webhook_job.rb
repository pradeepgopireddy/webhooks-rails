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

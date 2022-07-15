class OrdersController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_action :paypal_init, :except => [:index] 

  def index
  end
   
  def create_order
  # include URI
    price = '100.00'
    request = PayPalCheckoutSdk::Orders::OrdersCreateRequest::new
    request.request_body({
      :intent => 'CAPTURE',
      :purchase_units => [
        {
          :amount =>{
            :currency_code => 'USD',
            :value => price
          }
        }
      ]
    })
  
  begin 
    response = @client.execute request
    order = Order.new
    order.price = price.to_i
    order.token = response.result.id

    if order.save
      return render :json => {:token => response.result.id}, :status => :ok
    end
  rescue PayPalHttp::HttpError => ioe 
  end
  end

  def capture_order
    request = PayPalCheckoutSdk::Orders::OrdersCaptureRequest::new params[:order_id]

    begin
      response = @client.execute request
      order = Order.find_by :token => params[:order_id]
      order.paid = response.result.status == "COMPLETED"

      if order.save
        return render :json => {:status => response.result.status}, :status => :ok
      end
    rescue PayPalHttp::HttpError => ioe
    end
  end

  def paypal_init
    client_id = "AYgcS1SlT93z8ssith-OcakHf678xdNqzGnZic0lWqTbX6HnqYyRTdKM1BWQl7UII6TltxFYR718RuRq"
    client_secret = "EPeOI8DEyD-qkEcRB8Q8lOdsYlRJOj-jTP4GT7t9fQ22PwtQWh4xdUf_Zo1k9enNDdFQ8R2A7iWJdsru"

    environment = PayPal::SandboxEnvironment.new client_id, client_secret
    @client = PayPal::PayPalHttpClient.new environment
  end

end

class ActionController::Base 
  # Ensure that all controllers have direct access to assert_request.
  include AssertRequest

  # In production mode, trap assert_request's RequestError exceptions, and
  # render a 404 response instead.
  def rescue_action_in_public_with_request_error(exception)
    if exception.kind_of? RequestError
      render :file => "#{RAILS_ROOT}/public/404.html", :status => "404 Not Found"
    end
  end
  alias_method_chain :rescue_action_in_public, :request_error
  
end
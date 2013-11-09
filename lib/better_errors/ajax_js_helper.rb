module AjaxJsHelper

    # better_error_ajax helper method
    # Loads the assets related to the better errors ajax iframe in development enviroment
  def better_error_ajax
    if Rails.env.development?
        stylesheet_link_tag("better_errors_ajax")+javascript_include_tag("better_errors_ajax")
    end
  end
end

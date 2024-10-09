require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get events_url
    assert_response :success
  end

  test "should get new events page" do
    get new_event_url
    assert_redirected_to new_session_url

    User.create!(email_address: "foo@bar.com", name: "Foo Bar", password: "password")
    post session_url, params: { email_address: "foo@bar.com", password: "password" }
    assert_redirected_to new_event_url
    follow_redirect!
    assert_response :success
  end
end

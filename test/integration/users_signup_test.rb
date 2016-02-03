require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  
  def setup
    ActionMailer::Base.deliveries.clear
  end
  
  test 'invalid signup notification' do 
    get signup_path
    assert_no_difference 'User.count' do
      post users_path, user: {name: "abc", email: "abc@abc", password: "foo", password_confirmation: "bar"}
    end
    assert_template 'users/new'
    assert_select "div#error_explanation"
    assert_select "div.field_with_errors"
  end
  
  test "valid signup information with account activation" do 
    get signup_path
    assert_difference 'User.count', 1 do 
      post users_path, user: {name: "Foo Bar", email: "foobar@foobar.com", password: "foobar", password_confirmation: "foobar"}
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user)
    assert_not user.activated?
    
    # attempt to login before activation
    log_in_as(user)
    assert_not is_logged_in?
    
    get edit_account_activation_path("invalid token")
    assert_not is_logged_in?
    
    get edit_account_activation_path(user.activation_token, email: "wrong")
    assert_not is_logged_in?
    
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?
    
    follow_redirect!
    
    assert_template 'users/show'
    #assert_not flash.empty?
    assert is_logged_in?
  end
end

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(name: "Michael Hartl", email: "michael@hartl.com", password: "happyface", password_confirmation: "happyface")
  end
  
  test "should be valid" do
    assert @user.valid?
  end
  
  test "name should not be blank" do
    @user.name = "    "
    assert_not @user.valid?
  end
  
  test "email should not be blank" do
    @user.email = "     "
    assert_not @user.valid?
  end
  
  test "name should not be too long" do 
    @user.name = "a" * 51
    assert_not @user.valid?
  end
  
  test "email should not be too long" do
    @user.email = "a"*244 + "@example.com"
    assert_not @user.valid?
  end
  
  test "email validation should accept valid email addresses" do
    valid_addresses = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org
                         first.last@foo.jp alice+bob@baz.cn]
    valid_addresses.each do |valid_address|
      @user.email = valid_address
      assert @user.valid?, "#{@user.email} should be valid"
    end
  end
  
  test "email validation should reject invalid email addresses" do 
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
                           foo@bar_baz.com foo@bar+baz.com foo@bar..com]
    invalid_addresses.each do |invalid_address|
      @user.email = invalid_address
      assert_not @user.valid?, "#{@user.email} should be invalid."
    end
  end
  
  test "email address should be unique" do  
    @user.email = "foo@bar.com"
    @user.save
    @user2 = User.new(name: "WWL", email: "FOO@BAR.com")
    assert_not @user2.valid?, "duplicate email addresses should not be accepted"
  end
  
  test "email addresses should be saved as lowercase" do 
    @user.email = "FoO@bAr.com"
    @user.save
    assert_equal "foo@bar.com", @user.email
  end
  
  test "password should be present" do 
    @user.password = " "
    assert_not @user.valid?
  end
  
  test "password should have at least 5 characters" do 
    @user.password = "a" * 5
    assert_not @user.valid?
  end
  
  test "authenticated? should return false for a user with nil digest" do 
    assert_not @user.authenticated?(:remember, nil)
  end
  
  test "associated microposts should be destroyed" do 
    @user.save
    @user.microposts.create!(content: "Lorem ipsum")
    assert_difference 'Micropost.count', -1 do 
      @user.destroy
    end
  end
  
  test "following and unfollowing should work" do 
    michael = users(:michael)
    archer = users(:archer)
    assert_not michael.following?(archer)
    michael.follow(archer)
    assert michael.following?(archer)
    assert archer.followers.include?(michael)
    michael.unfollow(archer)
    assert_not michael.following?(archer)
  end
  
  test "feed should have the right posts" do 
    michael = users(:michael)
    archer = users(:archer)
    lana = users(:lana)
    # Posts from followed user
    lana.microposts.each do |post_following|
      assert michael.feed.include?(post_following)
    end
    michael.microposts.each do |post_self|
      assert michael.feed.include?(post_self)
    end
    archer.microposts.each do |post_not_following|
      assert_not michael.feed.include?(post_not_following)
    end
  end
end

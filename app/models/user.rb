class User < ActiveRecord::Base
    has_many :microposts, dependent: :destroy
    
    has_many :active_relationships, class_name: "Relationship", foreign_key: "follower_id", dependent: :destroy
    has_many :following, through: :active_relationships, source: :followed
    
    has_many :passive_relationships, class_name: "Relationship", foreign_key: "followed_id", dependent: :destroy
    has_many :followers, through: :passive_relationships
    
    attr_accessor :remember_token, :activation_token, :reset_token
    before_save {self.email.downcase!}
    before_create :create_activation_digest
    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
    validates(:name, presence: true, length: {maximum: 50})
    validates :email, presence: true, length: {maximum: 255}
    validates :email, format: {with: VALID_EMAIL_REGEX}, uniqueness: {case_sensitive: false}
    has_secure_password
    validates :password, presence: true, length: {minimum: 5, maximum: 100}, allow_nil: true
    
    def activate
        update_attribute(:activated, true)
        update_attribute(:activated_at, Time.zone.now)
    end
    
    def send_activation_email
        UserMailer.account_activation(self).deliver_now
    end
    
    def User.digest(string)
        cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
        BCrypt::Password.create(string, cost: cost)
    end
    
    def User.new_token
        SecureRandom.urlsafe_base64
    end
    
    def remember 
        self.remember_token = User.new_token
        update_attribute(:remember_digest, User.digest(remember_token)) # do not use the symbol version of remember_token!
    end
    
    def authenticated?(attribute, token)
        digest = self.send("#{attribute}_digest")
        return false if digest.nil?
        BCrypt::Password.new(digest).is_password?(token)
    end
    
    def forget
        update_attribute(:remember_digest, nil)
    end
    
    def create_activation_digest
        self.activation_token = User.new_token
        self.activation_digest = User.digest(activation_token)
    end
    
    def create_reset_digest
        self.reset_token = User.new_token
        update_attribute(:reset_digest,  User.digest(reset_token))
        update_attribute(:reset_sent_at, Time.zone.now)
    end
    
    def send_password_reset_email
        UserMailer.password_reset(self).deliver_now
    end
    
    def password_reset_expired?
        reset_sent_at < 2.hours.ago
    end
    
    def feed
        following_ids = "SELECT followed_id FROM relationships WHERE follower_id = :user_id"
        Micropost.where("user_id IN (#{following_ids}) OR user_id = :user_id", user_id: id)
    end
    
    # following and unfollowing
    def follow(other_user)
        active_relationships.create(followed_id: other_user.id)
    end
    
    def unfollow(other_user)
        active_relationships.find_by(followed_id: other_user.id).destroy
    end
    
    def following?(other_user)
        active_relationships.find_by(followed_id: other_user.id) != nil
        # or following.include?(other_user)
    end
end

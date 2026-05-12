class UserSerializer
  def initialize(user)
    @user = user
  end

  def as_json(*)
    {
      id: @user.id,
      email_address: @user.email_address,
      name: @user.name,
      admin: @user.admin?
    }
  end
end

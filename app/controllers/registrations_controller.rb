class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: [:new, :create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_url, alert: "Try again later." }

  def new
    @user = User.new
  end

  # def create
  #   @user = User.new(user_params)
  #   if @user.save
  #     if user = User.authenticate_by(email_address: params[:user][:email_address], password: params[:user][:password])
  #       start_new_session_for user
  #       redirect_to after_authentication_url
  #     else
  #       redirect_to new_registration_url, alert: "Registration successful, but unable to log in. Please try logging in manually."
  #     end
  #   else
  #     redirect_to new_registration_url, alert: "Registration failed. Please try again."
  #   end
  # end 

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for @user
      redirect_to after_authentication_url, notice: "Welcome! You have signed up successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :name)
  end
end

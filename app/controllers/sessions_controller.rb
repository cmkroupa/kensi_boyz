# A shared PIN keeps bots and randos out; a long-lived cookie means roommates
# only type it once per device. A second PIN signs in as admin (can edit games).
class SessionsController < ApplicationController
  COOKIE = :kfl_access
  PASSCODES = { "7742" => "member", "2477" => "admin" }.freeze

  skip_before_action :require_passcode
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Too many tries. Wait a few minutes." }

  def new
    redirect_to root_path if authenticated?
  end

  def create
    role = PASSCODES.find { |code, _| ActiveSupport::SecurityUtils.secure_compare(params[:passcode].to_s, code) }&.last
    if role
      cookies.signed[COOKIE] = { value: role, expires: 1.year, httponly: true, same_site: :lax }
      redirect_to root_path
    else
      redirect_to new_session_path, alert: "Wrong passcode."
    end
  end

  def destroy
    cookies.delete(COOKIE)
    redirect_to new_session_path
  end
end

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_passcode

  helper_method :current_mode, :authenticated?, :admin?

  private
    def authenticated?
      SessionsController::PASSCODES.value?(cookies.signed[SessionsController::COOKIE])
    end

    def admin?
      cookies.signed[SessionsController::COOKIE] == "admin"
    end

    def require_admin
      redirect_back_or_to root_path, alert: "Admins only." unless admin?
    end

    def require_passcode
      redirect_to new_session_path unless authenticated?
    end

    # 1v1 vs 2v2 is carried in the URL so every page can be linked to directly.
    def current_mode
      Game.modes.key?(params[:mode]) ? params[:mode] : "singles"
    end
end

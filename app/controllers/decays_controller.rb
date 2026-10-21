# Admins can switch rating decay on and off; ratings are replayed straight away.
class DecaysController < ApplicationController
  before_action :require_admin

  def create
    switch(true)
    redirect_back_or_to root_path, notice: "Rating decay is on."
  end

  def destroy
    switch(false)
    redirect_back_or_to root_path, notice: "Rating decay is off."
  end

  private
    def switch(on)
      Setting.switch("decay", on)
      RatingReplay.call
    end
end


class InternalApi::DiscussionsController < ApplicationController
  before_action :authenticate_user

  def create
    discussionable = find_discussionable
    discussion = discussionable.discussions.build(discussion_params)
    discussion.user = current_user

    if discussion.save
      render json: discussion.as_json_data, status: :created
    else
      render json: discussion.errors, status: :unprocessable_entity
    end
  end

  private

  def discussion_params
    params.permit(:title)
  end

  def find_discussionable
    params[:discussionable_type].classify.constantize.find(params[:discussionable_id])
  end
end
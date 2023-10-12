class Api::SpacesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_current_user

  def index
    @spaces = policy_scope(Space).order(created_at: :desc).page(params[:page])
    @spaces = @spaces.where(user_id: current_user.id) if cookies[:mySpaces] == 'true'
    render json: {spaces: @spaces.to_json}
  end

  def show
    space = Space.find_by(space_starchain_id: params[:id])
    return render json: {message: "Space not found"}, status: :not_found unless space

    render json: {
      tags: space.tags.to_json,
      cover_image: space.cover_image_url
    }
  end

  def create
    space = Space.new(create_params.slice(:space_starchain_id, :title, :desc, :site_link, :space_type))
    new_tags = []
    create_params[:tags].split(',').each do |tag_name|
      tag = Tag.find_by(name: tag_name.strip)
      unless tag
        tag = Tag.create(name: tag_name.strip, color: random_color)
      end
      new_tags << tag
    end
    space.tags = new_tags
    space.user = @current_user
    if space.save
      render json: { message: "Space created",
                     space_address: "#{request.base_url}/spaces/#{space.space_starchain_id}" }
    else
      render json: {message: "Failed to create space"}, status: :bad_request
    end
  end

  def update
    space = Space.find_by(space_starchain_id: params[:id])
    return render json: {message: "Space not found"}, status: :not_found unless space

    if space.user.id != current_user.id
      return render json: {message: "Unauthrorized"}, status: :unauthorized
    end

    if space.update(update_params)
      render json: {message: "Space updated"}
    else
      render json: {message: "Failed to update space"}, status: :bad_request
    end
  end

  def destroy
    space = Space.find_by(space_starchain_id: params[:id])
    return render json: {message: "Space not found"}, status: :not_found unless space

    if space.user.id != current_user.id
      return render json: {message: "Unauthrorized"}, status: :unauthorized
    end

    if space.destroy
      render json: {message: "Space destroyed"}
    else
      render json: {message: "Failed to destroy space"}
    end
  end

  private

  def create_params
    params.permit(:space_starchain_id, :title, :desc, :site_link, :space_type, :tags)
  end

  def update_params
    params.permit(:title, :desc, :site_link, :space_type, :status)
  end

  def id_token
    request.headers["Authorization"].to_s.split(' ').last
  end

  def user_info
    JWT.decode(id_token, nil, false).first
  rescue JWT::DecodeError
    {}
  end

  def current_user
    User.find_by(login_identity: user_info['sub'])
  end

  def set_current_user
    if current_user
      @current_user = current_user
    else
      return render json: {message: "User not found"}, status: :not_found
    end
  end

  def random_color
    "##{random_color_hex}"
  end

  def random_color_hex
    "%06x" % (rand * 0xffffff)
  end
end
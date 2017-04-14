class ArticlesController < ApplicationController

  def new
  end

  def create
    # The render method here is taking a very simple hash
    # with a key of :plain and value of params[:article].inspect.
    #
    # The params method is the object which represents the parameters 
    # (or fields) coming in from the form. 
    # --> returns an ActionController::Parameters object, which allows 
    #     you to access the keys of the hash using either strings or symbols. 
    render plain: params[:article].inspect
  end

end

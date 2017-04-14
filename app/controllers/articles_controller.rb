class ArticlesController < ApplicationController
  def index
    @articles = Article.all
  end

  def show
    # find the article we're interested in - pass in params[.id] to get
    # :id parameter from the request and save it in instance of article object.
    @article = Article.find(params[:id])
  end

  def new
  end

  def create
    # initialize model with  attributes, map them to db columns and
    @article = Article.new(article_params)
    # save model in db
    @article.save
    # redirect to show action
    redirect_to @article
  end

  private
    def article_params
      # whitelist controller parameters to prevent wrongful mass assignment
      params.require(:article).permit(:title, :text)
    end

end

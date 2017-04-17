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
    # we need to create the instance because otherwise it would be nil in our view
    # and the error-validation would throw an error
    @article = Article.new
  end

  def edit
    @article = Article.find(params[:id])
  end

  def create
    # initialize model with  attributes, map them to db columns and
    @article = Article.new(article_params)

     # if saveing model in db was successfull
    if @article.save
      # redirect to show action
      redirect_to @article
    else
      render 'new'
    end
  end

  def update
    @article = Article.find(params[:id])

    if @article.update(article_params)
      redirect_to @article
    else
      render 'edit'
    end
  end

  def destroy
    @article = Article.find(params[:id])
    @article.destroy
    
    redirect_to articles_path
  end

  private
    def article_params
      # whitelist controller parameters to prevent wrongful mass assignment
      params.require(:article).permit(:title, :text)
    end

end

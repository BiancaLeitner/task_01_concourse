class CommentsController < ApplicationController

  def create
    # Each request for a comment has to keep track of the article 
    # to which the comment is attached,
    @article = Article.find(params[:article_id])
    # create and save the comment (will also link comment to article)
    @comment = @article.comments.create(comment_params)
    # send back to original article
    redirect_to article_path(@article)
  end

  def destroy
    @article = Article.find(params[:article_id])
    @comment = @article.comments.find(params[:id])
    @comment.destroy
    redirect_to article_path(@article)
  end

  private
    def comment_params
      params.require(:comment).permit(:commenter, :body)
    end
end

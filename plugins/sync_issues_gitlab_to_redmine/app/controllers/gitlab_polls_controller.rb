class GitlabPollsController < ApplicationController

  def index
    @project = Project.find(params[:project_id])
    @polls = GitlabPoll.all
  end

  def vote
    poll = GitlabPoll.find(params[:id])
    poll.vote(params[:answer])
    if poll.save
      flash[:notice] = 'Vote saved.'
    end
    redirect_to :action => 'index', project_id: params[:project_id]
  end
end

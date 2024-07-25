require "uri"
require "net/http"

class GitlabPollsController < ApplicationController

  def index
    @project = Project.find(params[:project_id])
    @polls = GitlabPoll.all

    url = URI("https://gitlab.nal.vn/api/v4/projects?PRIVATE_TOKEN=-TKxxs5BXX8PSrT1Vjmb")

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(url)

    response = https.request(request)
    puts response.read_body

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

require "uri"
require "net/http"
require "json"

class GitlabPollsController < ApplicationController

  def index
    @project = Project.find(params[:project_id])
    @polls = GitlabPoll.all

    gitlab_client = GitLabClient.new('-TKxxs5BXX8PSrT1Vjmb')

    endpoint = "https://gitlab.nal.vn/api/v4/projects"
    response_body = gitlab_client.call_api(endpoint)

    if response_body
      @gitlab_projects = JSON.parse(response_body)
    else
      @gitlab_projects = []
    end
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

class GitLabClient
  def initialize(private_token)
    @private_token = private_token
  end

  def call_api(endpoint)
    url = URI("#{endpoint}?PRIVATE_TOKEN=#{@private_token}")

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(url)
    response = https.request(request)

    response.body
  rescue StandardError => e
    puts "Error fetching data: #{e.message}"
    nil
  end
end

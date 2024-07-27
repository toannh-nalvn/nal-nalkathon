require 'rest-client'
require 'json'

class GitlabImporterController < ApplicationController
  skip_forgery_protection
  GITLAB_API_PATH = 'https://gitlab.nal.vn/api/v4'
  DEFAULT_TRACKER_ID = 2 # 1: BUG, 2: FEATURE, 3: Support
  DEFAULT_STATUS = 1 # 1: New, 5: closed
  DEFAULT_PRIORITY = 2 # 1: Low, 2: Normal, 3: High
  DEFAULT_USER_ID = 5

  def index
    puts "Project's id: %s" % [params[:project_id]]
    @project = Project.find(params[:project_id])
    @issues_count = @project.issues.count
  end

  def import
    access_token = params[:access_token]
    project_id = params[:project_id]
    gitlab_project_id = params[:gitlab_project_id]
    issue_url = "#{GITLAB_API_PATH}/projects/#{gitlab_project_id}/issues?private_token=#{access_token}"

    redmine_project = Project.find_by_identifier(project_id)
    if redmine_project.nil?
      flash[:error] = l(:error_no_project)
    else
      begin
        response = RestClient.get(issue_url)
        issues = JSON.parse(response.body)
        issues.each { |issue|
          if Issue.exists?(:project_id => redmine_project.id, :subject => issue['title'])
            flash[:error] = "Some issues were already imported."
          else
            Issue.create({ :tracker_id => DEFAULT_TRACKER_ID,
                           :project_id => redmine_project.id,
                           :subject => issue['title'],
                           :description => issue['description'],
                           :due_date => issue['due_date'],
                           :status_id => DEFAULT_STATUS,
                           :priority_id => DEFAULT_PRIORITY,
                           :author_id => DEFAULT_USER_ID,
                           :created_on => issue['created_at'],
                           :updated_on => issue['updated_at']
                         })
            # insert_sql = "INSERT INTO issues "\
            #   "(tracker_id, project_id, subject, description, due_date, status_id, priority_id, author_id, created_on, updated_on)"\
            #   " VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
          end
        }
        flash[:notice] = "Imported issues successfully."
      rescue RestClient::Exception => e
        flash[:error] = e.message
      end
    end
    redirect_to :action => 'index', project_id: params[:project_id]
  end
end

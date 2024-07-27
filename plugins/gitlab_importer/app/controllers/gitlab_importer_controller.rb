require 'rest-client'
require 'json'

class GitlabImporterController < ApplicationController
  # before_action :authorize
  skip_forgery_protection
  GITLAB_API_PATH = 'https://gitlab.nal.vn/api/v4'
  DEFAULT_TRACKER_ID = 2 # 1: BUG, 2: FEATURE, 3: Support
  NEW_STATUS = 1
  CLOSED_STATUS = 5
  DEFAULT_PRIORITY = 2 # 1: Low, 2: Normal, 3: High
  DEFAULT_USER_ID = 5
  LOW_PRIORITY = 1
  NORMAL_PRIORITY = 2
  HIGH_PRIORITY = 3

  def index
    puts "Project's id: %s" % [params[:project_id]]
    @project = Project.find(params[:project_id])
    @issues_count = @project.issues.count
  end

  def setting
    redmine_project = Project.find(params[:project_id])
    if redmine_project.nil?
      flash[:error] = l(:error_no_project)
      return
    end

    @setting = GitlabImportSetting.find_by_project_id(params[redmine_project.id])
  end

  def update_setting
    project_id = params[:project_id]
    redmine_project = Project.find_by_identifier(project_id)
    if redmine_project.nil?
      flash[:error] = l(:error_no_project)
      redirect_to :action => 'index', project_id: params[:project_id]
      return
    end
    access_token = params[:access_token]
    gitlab_project_id = params[:gitlab_project_id]
    issue_parent_label = params[:issue_parent_label]
    GitlabImportSetting.create({
      project_id: redmine_project.id,
      gitlab_project_id: gitlab_project_id,
      access_token: access_token,
      issue_parent_label: issue_parent_label })
    flash[:notice] = "Import settings were successfully."
    redirect_to :action => 'setting', project_id: project_id
  end

  def import
    project_id = params[:project_id]
    redmine_project = Project.find_by_identifier(project_id)
    if redmine_project.nil?
      flash[:error] = l(:error_no_project)
      redirect_to :action => 'index', project_id: params[:project_id]
      return
    end
    imported_issue_count = 0
    access_token = params[:access_token]
    gitlab_project_id = params[:gitlab_project_id]
    issue_url = "#{GITLAB_API_PATH}/projects/#{gitlab_project_id}/issues?per_page=100"
    begin
      response = RestClient::Request.execute(method: :get, url: issue_url, headers: {'private-token' => access_token})
      issues = JSON.parse(response.body)
      issues.each { |issue|
        if Issue.exists?(:project_id => redmine_project.id, :subject => issue['title'])
          next
        end
        user = User.find_by_login(issue['author']['username'])
        author_id = User.current.id
        unless user.nil?
          author_id = user.id
        end
        status_id = NEW_STATUS
        if issue['state'] == 'closed'
          status_id = CLOSED_STATUS
        end
        assignee_id = nil
        unless issue['assignee'].nil?
          assignee_user = User.find_by_login(issue['assignee']['username'])
          unless assignee_user.nil?
            assignee_id = assignee_user.id
          end
        end
        issue_labels = issue['labels']
        Issue.create({ :tracker_id => DEFAULT_TRACKER_ID,
                       :project_id => redmine_project.id,
                       :subject => issue['title'],
                       :description => issue['description'],
                       :due_date => issue['due_date'],
                       :status_id => status_id,
                       :priority_id => DEFAULT_PRIORITY,
                       :author_id => author_id,
                       :assigned_to_id => assignee_id,
                       :created_on => issue['created_at'],
                       :updated_on => issue['updated_at']
                     })
        imported_issue_count += 1
      }
      if imported_issue_count == 0
        flash[:error] = "There is no issues imported! They may be imported before."
      else
        flash[:notice] = "There are #{imported_issue_count} issues have been imported successfully."
      end
      redirect_to :action => 'index', project_id: params[:project_id]
    rescue RestClient::Exception => e
      flash[:error] = e.message
      redirect_to :action => 'index', project_id: params[:project_id]
    end
  end
end

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

  def get_gitlab_project(project_id, token)
    project_url = "#{GITLAB_API_PATH}/projects/#{project_id}"
    response = RestClient::Request.execute(method: :get, url: project_url, headers: {'private-token' => token})
    JSON.parse(response.body)
  end

  def get_gitlab_projects(token)
    project_url = "#{GITLAB_API_PATH}/projects?per_page=100"
    response = RestClient::Request.execute(method: :get, url: project_url, headers: {'private-token' => token})
    JSON.parse(response.body)
  end

  def get_gitlab_label(project_id, label_id, token)
    label_url = "#{GITLAB_API_PATH}/projects/#{project_id}/labels/#{label_id}"
    response = RestClient::Request.execute(method: :get, url: label_url, headers: {'private-token' => token})
    JSON.parse(response.body)
  end

  def get_gitlab_labels(project_id, token)
    label_url = "#{GITLAB_API_PATH}/projects/#{project_id}/labels?per_page=100"
    response = RestClient::Request.execute(method: :get, url: label_url, headers: {'private-token' => token})
    JSON.parse(response.body)
  end

  def get_gitlab_milestones(project_id, token)
    milestone_url = "#{GITLAB_API_PATH}/projects/#{project_id}/milestones?per_page=100"
    response = RestClient::Request.execute(method: :get, url: milestone_url, headers: {'private-token' => token})
    JSON.parse(response.body)
  end

  def index
    project_id = params[:project_id]
    @project = Project.find(project_id)
    if @project.nil?
      flash[:error] = l(:error_no_project)
      return
    end
    @issues_count = @project.issues.count
    @setting = GitlabImportSetting.find_by_project_id(@project.id)
    if @setting.nil?
      redirect_to :action => 'setting', project_id: project_id
      return
    end
    @gitlab_project = get_gitlab_project(@setting.gitlab_project_id, @setting.access_token)
    @gitlab_labels = get_gitlab_labels(@setting.gitlab_project_id, @setting.access_token)
    @gitlab_milestones = get_gitlab_milestones(@setting.gitlab_project_id, @setting.access_token)
  end

  def setting
    project_id = params[:project_id]
    @project = Project.find(project_id)
    if @project.nil?
      flash[:error] = l(:error_no_project)
      return
    end

    @setting = GitlabImportSetting.find_by_project_id(@project.id)
    unless @setting.nil?
      @gitlab_projects = get_gitlab_projects(@setting.access_token)
      @gitlab_labels = get_gitlab_labels(@setting.gitlab_project_id, @setting.access_token)
    end
  end

  def update_setting
    project_id = params[:project_id]
    redmine_project = Project.find_by_identifier(project_id)
    if redmine_project.nil?
      flash[:error] = l(:error_no_project)
      redirect_to :action => 'setting', project_id: params[:project_id]
      return
    end
    access_token = params[:access_token]
    gitlab_project_id = params[:gitlab_project_id]
    parent_label_id = params[:issue_parent_label]
    import_milestone = params[:import_milestone]
    setting = GitlabImportSetting.find_by_project_id(redmine_project.id)
    if setting.nil?
      begin
        setting = GitlabImportSetting.new({
                                   :project_id => redmine_project.id,
                                   :gitlab_project_id => gitlab_project_id,
                                   :access_token => access_token,
                                   :parent_label_id => parent_label_id})
        if setting.valid?
          setting.save
        else
          flash[:error] = 'Invalid project setting'
          redirect_to :action => 'setting', project_id: project_id
          return
        end
      rescue Exception => e
        flash[:error] = e.message
        redirect_to :action => 'setting', project_id: params[:project_id]
        return
      end
    else
      setting.gitlab_project_id = gitlab_project_id
      setting.access_token = access_token
      setting.parent_label_id = parent_label_id
      setting.save
    end

    if import_milestone
      # @gitlab_projects = get_gitlab_projects(setting.access_token).map { |p| OptionSelect.new(p['id'], p['name']) }
    end
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
    setting = GitlabImportSetting.find_by_project_id(redmine_project.id)
    imported_issue_count = 0
    gitlab_project_id = setting.gitlab_project_id
    access_token = setting.access_token
    milestone_id = params[:milestone]
    issue_label = params[:label]
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
        priority_id = NORMAL_PRIORITY
        if issue_labels.find { |label| 'High'.casecmp(label['name'] == 0)}
          priority_id = HIGH_PRIORITY
        end
        if issue_labels.find { |label| 'Normal'.casecmp(label['name']) == 0 || 'Medium'.casecmp(label['name']) == 0}
          priority_id = NORMAL_PRIORITY
        end

        trackers = Tracker.all

        Issue.create({ :tracker_id => DEFAULT_TRACKER_ID,
                       :project_id => redmine_project.id,
                       :subject => issue['title'],
                       :description => issue['description'],
                       :due_date => issue['due_date'],
                       :status_id => status_id,
                       :priority_id => priority_id,
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

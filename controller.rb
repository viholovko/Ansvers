# Below is some obscure controller action with related module
#
# Do you think it could be improved? What are your ideas for refactoring without seeing whole picture?
# Can you suggest some better approach?
#
# Feel free to assume what is going on and what potentially could be improved
# Eg. you can write new controller/action/module and add some comments with your thought process
# 
# - share a secret gist with your proposed solution

# As I see module is important for checking permission. Much better to replace this code to validate. Another 
# side is rebasing logic to modele. About emails much better to create an after_create method and replace the
# code for email notifications in a separate way that does not depend on the main logic. The possible code has 
# some errors. I don't have the ability to check and add specs for this code. Additionally, I have not added a 
# relation to other models. But in real code, it must exist.

# Changed code is bellow.



class ContactRequest < ApplicationRecord
  after_create :email_for_contact_request_employer
  include Concerns::V5::ContactRequestParticipateable

  def email_for_contact_request_employer
    job = self.job

    return unless job

    EmailNotification.delay.contact_request_employer(recipient_address: job.creator.email,
                                                       tradesman: self.user,
                                                       job: job,
                                                       job_url: permalink_job_comparisons_url(job.token, contact_request: true),
                                                       contact_request_id: self.id,
                                                       job_creator: job.creator,
                                                       subject: I18n.t(:Contact_request_for, job_title: job.title),
                                                       purpose: ContactRequest::PURPOSE[self.purpose.to_sym])
  end  

end  

class ContactRequestsController < ApplicationController
  before_action :needs_tradesman_login, only: [:create]

  def create
    @job = Job.find_by_id(params[:job_id])
    redirect_back(fallback_location: users_path) and return unless @job

    @contact_request = ContactRequest.new(user_id: current_user.id,
                                          job_id: @job.id,
                                          purpose: params[:purpose])

    if @contact_request.save
      redirect_back fallback_location: job_path(@job)
      flash[:notice] = t(:Contact_request_sent_to_employer)
    else
      if @contact_request.errors[:not_premium_member].any?
        flash[:error] = @contact_request.errors[:not_premium_member].html_safe
        redirect_to new_user_subscription_path(current_user)
      else
        redirect_to job_path(@job)
        flash[:error] = @contact_request.errors.full_messages.join(', <br> ').html_safe
      end
    end
  end
end

module Concerns::V5::ContactRequestParticipateable
  extend ActiveSupport::Concern

  included do
    validate :requires_premium_membership, :before => :create
  end

  private

  def requires_premium_membership()
    return unless self.user.pricings.current.v5?
    
    @job = self.job
    @user = self.user

    if participate_as_basic_member?(user: @user)
      errors.add(:not_premium_member, "Participation only possible for premium members") 
    end
  end

  def participate_as_basic_member?(args)
    user = args[:user]
    current_subscription = user.subscriptions.last

    current_subscription.blank? || (current_subscription && !current_subscription.is_valid?)
  end
end

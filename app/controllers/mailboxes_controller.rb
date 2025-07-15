class MailboxesController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications.includes(:event).order(created_at: :desc).page(params[:page]).per(20)
  end

  def show
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read! unless @notification.read?
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_to mailboxes_path, notice: 'All notifications marked as read'
  end

  def mark_as_read
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!

    respond_to do |format|
      format.html { redirect_to mailboxes_path }
      format.json { render json: { success: true } }
    end
  end

  def destroy
    @notification = current_user.notifications.find(params[:id])
    @notification.destroy

    respond_to do |format|
      format.html { redirect_to mailboxes_path, notice: 'Notification deleted' }
      format.json { render json: { success: true } }
    end
  end
end

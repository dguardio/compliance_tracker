class CommentPolicy < ApplicationPolicy
  def index?
    # Used for Evidence Dashboard
    can?(:read, 'Comment') || can?(:read, 'EvidenceRequest')
  end

  def show?
    can?(:read, 'Comment', record)
  end

  def create?
    # Users can comment if they can read the parent resource
    # But strictly speaking, we might want a specific permission
    can?(:create, 'Comment') || can?(:read, record.commentable.class.name, record.commentable)
  end

  def new?
    create?
  end

  def update?
    # Users can update their own comments
    return true if record.user_id == user.id
    can?(:update, 'Comment', record)
  end

  def edit?
    update?
  end

  def destroy?
    # Users can delete their own comments
    return true if record.user_id == user.id
    can?(:destroy, 'Comment', record)
  end

  class Scope < Scope
    def resolve
      return scope.none unless user&.organization

      if user.has_permission?(:read, 'Comment')
        # Ensure we only show comments for the user's organization
        # Since Comment doesn't have acts_as_tenant, we must join user
        scope.joins(:user).where(users: { organization_id: user.organization_id })
      else
        # By default, users can see comments on things they can see
        # But for the Evidence Dashboard, we might want to restrict
        # For now, return all comments in the organization
        # Filtering happens at the controller/view level usually based on parent visibility
        scope.joins(:user).where(users: { organization_id: user.organization_id })
      end
    end
  end
end

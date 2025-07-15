class DocumentPolicy < ApplicationPolicy
  # The standard Pundit methods (index?, show?, create?, update?, destroy?) 
  # are already handled by ApplicationPolicy and use the database permissions

  def approve?
    # Users can approve documents if they have manage permission for documents
    # or if they are in the approval workflow
    return true if can?(:manage, 'Document')
    return true if record&.can_be_approved_by?(user)
    
    false
  end

  def reject?
    # Same as approve
    approve?
  end

  def archive?
    # Users can archive documents if they have update permission
    update?
  end

  def duplicate?
    # Users can duplicate documents if they have create permission
    create?
  end

  def submit_for_review?
    # Users can submit documents for review if they have update permission
    update?
  end

  # Scope class for index actions - already handled by ApplicationPolicy
  # but we can override if we need document-specific logic
  class Scope < Scope
    def resolve
      return @scope.none unless @user&.organization

      # Get permissions for documents
      permissions = @user.organization.permissions.for_user(@user)
                         .for_action('read')
                         .for_resource_type('Document')

      # If user has global read permission for documents, return all
      if permissions.any? { |p| p.global? && p.can_perform?(@user) }
        @scope.all
      else
        # Filter based on specific document permissions
        allowed_document_ids = []

        permissions.each do |permission|
          if permission.resource_specific? && permission.can_perform?(@user, permission.resource)
            allowed_document_ids << permission.resource_id
          end
        end

        if allowed_document_ids.any?
          @scope.where(id: allowed_document_ids)
        else
          @scope.none
        end
      end
    end
  end
end

class RiskAssessmentPolicy < ApplicationPolicy
  # All standard Pundit methods (index?, show?, create?, update?, destroy?, manage?)
  # are inherited from ApplicationPolicy and will use the dynamic permission system

  # Custom scope for risk assessments
  class Scope < Scope
    def resolve
      return @scope.none unless @user&.organization

      # Get permissions for RiskAssessment resource type
      permissions = @user.organization.permissions.for_user(@user)
                         .for_action('read')
                         .for_resource_type('RiskAssessment')

      # If user has global read permission for RiskAssessment, return all
      if permissions.any? { |p| p.global? && p.can_perform?(@user) }
        @scope.where(organization: @user.organization)
      else
        # Filter based on specific resource permissions and ownership
        allowed_resource_ids = []

        permissions.each do |permission|
          if permission.resource_specific? && permission.can_perform?(@user, permission.resource)
            allowed_resource_ids << permission.resource_id
          end
        end

        # Also include risk assessments where user is creator or assignee
        user_owned_assessments = @scope.where(organization: @user.organization)
                                       .where('created_by_id = ? OR assigned_to_id = ?', @user.id, @user.id)

        if allowed_resource_ids.any?
          @scope.where(organization: @user.organization)
                .where('id IN (?) OR created_by_id = ? OR assigned_to_id = ?',
                       allowed_resource_ids, @user.id, @user.id)
        else
          user_owned_assessments
        end
      end
    end
  end

  # Additional custom methods for risk assessment specific logic
  def can_review?
    can?(:review, 'RiskAssessment', record) ||
      record.assigned_to == user ||
      record.created_by == user
  end

  def can_approve?
    can?(:approve, 'RiskAssessment', record)
  end

  def can_assign?
    can?(:assign, 'RiskAssessment', record)
  end
end

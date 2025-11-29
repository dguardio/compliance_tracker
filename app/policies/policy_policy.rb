class PolicyPolicy < ApplicationPolicy
  def index?
    # Check if user has global read permission or specific permission
    can?(:read, 'Policy')
  end

  def show?
    can?(:read, 'Policy', record)
  end

  def create?
    can?(:create, 'Policy')
  end

  def new?
    create?
  end

  def update?
    can?(:update, 'Policy', record)
  end

  def edit?
    update?
  end

  def destroy?
    can?(:destroy, 'Policy', record)
  end

  class Scope < Scope
    def resolve
      return scope.none unless user&.organization

      # If user has global read permission for Policies, return all
      if user.has_permission?(:read, 'Policy')
        scope.all
      else
        # Otherwise, return only policies they have specific access to
        # (This might need refinement if we have specific policy assignments)
        # For now, we'll assume if they can read policies, they can read all in the org
        # But let's stick to the base Scope logic if possible, or override here.
        
        # Actually, the base Scope class handles:
        # 1. Global read permission for resource type -> all
        # 2. Specific resource permissions -> where(id: ids)
        
        super
      end
    end
  end
end

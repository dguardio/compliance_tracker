class RegulationPolicy < ApplicationPolicy
  def index?
    can?(:read, 'Regulation')
  end

  def show?
    can?(:read, 'Regulation', record)
  end

  def create?
    can?(:create, 'Regulation')
  end

  def new?
    create?
  end

  def update?
    can?(:update, 'Regulation', record)
  end

  def edit?
    update?
  end

  def destroy?
    can?(:destroy, 'Regulation', record)
  end

  def bulk_delete?
    can?(:destroy, 'Regulation')
  end

  def version?
    show?
  end

  def download_diff?
    show?
  end

  def workspace?
    show?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user&.organization

      if user.has_permission?(:read, 'Regulation')
        scope.all
      else
        super
      end
    end
  end
end

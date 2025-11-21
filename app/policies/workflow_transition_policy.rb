# frozen_string_literal: true

class WorkflowTransitionPolicy < ApplicationPolicy
  def create?
    can?(:create, record.class.name, record)
  end

  def update?
    can?(:update, record.class.name, record)
  end

  def destroy?
    can?(:destroy, record.class.name, record)
  end
end

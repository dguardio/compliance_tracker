class PolicyLink < ApplicationRecord
  belongs_to :policy
  belongs_to :linkable, polymorphic: true
end

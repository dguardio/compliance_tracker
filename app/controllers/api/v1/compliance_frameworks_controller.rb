module Api
  module V1
    class ComplianceFrameworksController < ApplicationController
      before_action :set_organization
      before_action :set_compliance_framework, only: [:show, :update, :destroy]
      before_action :authorize_compliance_framework
      skip_before_action :verify_authenticity_token

      def index
        @compliance_frameworks = @organization.compliance_frameworks.includes(:compliance_requirements)
        
        render json: {
          data: @compliance_frameworks.map do |framework|
            {
              id: framework.id,
              type: 'compliance_framework',
              attributes: {
                name: framework.name,
                slug: framework.slug,
                description: framework.description,
                version: framework.version,
                status: framework.status,
                settings: framework.settings,
                created_at: framework.created_at,
                updated_at: framework.updated_at
              },
              relationships: {
                compliance_requirements: {
                  data: framework.compliance_requirements.map do |req|
                    { id: req.id, type: 'compliance_requirement' }
                  end
                }
              }
            }
          end,
          meta: {
            total_count: @compliance_frameworks.count
          }
        }
      end

      def show
        render json: {
          data: {
            id: @compliance_framework.id,
            type: 'compliance_framework',
            attributes: {
              name: @compliance_framework.name,
              slug: @compliance_framework.slug,
              description: @compliance_framework.description,
              version: @compliance_framework.version,
              status: @compliance_framework.status,
              settings: @compliance_framework.settings,
              created_at: @compliance_framework.created_at,
              updated_at: @compliance_framework.updated_at
            },
            relationships: {
              compliance_requirements: {
                data: @compliance_framework.compliance_requirements.map do |req|
                  { id: req.id, type: 'compliance_requirement' }
                end
              }
            }
          }
        }
      end

      def create
        @compliance_framework = @organization.compliance_frameworks.build(compliance_framework_params)

        if @compliance_framework.save
          render json: {
            data: {
              id: @compliance_framework.id,
              type: 'compliance_framework',
              attributes: {
                name: @compliance_framework.name,
                slug: @compliance_framework.slug,
                description: @compliance_framework.description,
                version: @compliance_framework.version,
                status: @compliance_framework.status,
                settings: @compliance_framework.settings,
                created_at: @compliance_framework.created_at,
                updated_at: @compliance_framework.updated_at
              }
            }
          }, status: :created
        else
          render json: {
            errors: @compliance_framework.errors.full_messages.map do |message|
              { detail: message }
            end
          }, status: :unprocessable_entity
        end
      end

      def update
        if @compliance_framework.update(compliance_framework_params)
          render json: {
            data: {
              id: @compliance_framework.id,
              type: 'compliance_framework',
              attributes: {
                name: @compliance_framework.name,
                slug: @compliance_framework.slug,
                description: @compliance_framework.description,
                version: @compliance_framework.version,
                status: @compliance_framework.status,
                settings: @compliance_framework.settings,
                created_at: @compliance_framework.created_at,
                updated_at: @compliance_framework.updated_at
              }
            }
          }
        else
          render json: {
            errors: @compliance_framework.errors.full_messages.map do |message|
              { detail: message }
            end
          }, status: :unprocessable_entity
        end
      end

      def destroy
        @compliance_framework.destroy
        render json: { message: 'Compliance framework deleted successfully' }
      end

      private

      def set_organization
        @organization = Organization.find(params[:organization_id])
      end

      def set_compliance_framework
        @compliance_framework = @organization.compliance_frameworks.find(params[:id])
      end

      def compliance_framework_params
        params.require(:compliance_framework).permit(:name, :slug, :description, :version, :status, :settings)
      end

      def authorize_compliance_framework
        case action_name
        when 'index', 'show'
          authorize @compliance_framework || ComplianceFramework.new(organization: @organization), :read?
        when 'create'
          authorize ComplianceFramework.new(organization: @organization), :create?
        when 'update'
          authorize @compliance_framework, :update?
        when 'destroy'
          authorize @compliance_framework, :destroy?
        end
      end
    end
  end
end 
module Api
  module V1
    class IngestionsController < ApplicationController
      skip_before_action :verify_authenticity_token

      def create
        # In a real app we would want token authentication here to secure the webhook
        data_source = RegulatoryDataSource.find_by(id: params[:data_source_id])
        
        unless data_source
          return render json: { error: "Data source not found" }, status: :not_found
        end

        Regulation.transaction do
          regulation = Regulation.find_or_initialize_by(
            external_id: params[:url]
          )

          regulation.assign_attributes(
            title: params[:title],
            agency: data_source.provider.name,
            jurisdiction: data_source.provider.jurisdiction || 'US',
            publication_date: params[:publication_date],
            full_text: { 'main' => params[:content] },
            metadata: { 'source_url' => params[:url] },
            status: "active"
          )
          
          if regulation.save
            # Enqueue vectorization so the text is indexed for PgVector AI searches
            ::GenerateEmbeddingJob.perform_later(regulation)
            
            # Log the successful webhook execution using AgentTrace
            ::Ai::AgentTrace.create!(
              run_id: "webhook_#{SecureRandom.uuid}",
              agent_name: 'Python Scrapling Webhook',
              status: 'success',
              action: 'webhook_received',
              duration: 0.0,
              input: { url: params[:url] }
            )

            render json: { status: "success", regulation_id: regulation.id }, status: :created
          else
            render json: { error: regulation.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end

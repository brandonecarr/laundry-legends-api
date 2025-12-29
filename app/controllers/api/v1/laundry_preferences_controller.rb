# app/controllers/api/v1/laundry_preferences_controller.rb

module Api
  module V1
    class LaundryPreferencesController < ApplicationController
      # GET /api/v1/user/laundry-preferences
      def show
        preference = current_user.laundry_preference
        
        render json: {
          laundry_preference: preference_response(preference)
        }
      end
      
      # PUT /api/v1/user/laundry-preferences
      def update
        preference = current_user.laundry_preference || current_user.build_laundry_preference
        
        if preference.update(preference_params)
          render json: {
            laundry_preference: preference_response(preference)
          }
        else
          render json: { errors: preference.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      private
      
      def preference_params
        params.permit(
          :detergent_type, :water_temperature, :dry_method,
          :separate_kids_clothing, :sensitive_skin, :remove_pet_hair,
          :fold_only, :personal_notes
        )
      end
      
      def preference_response(preference)
        {
          id: preference.id,
          user_id: preference.user_id,
          detergent_type: preference.detergent_type,
          water_temperature: preference.water_temperature,
          dry_method: preference.dry_method,
          separate_kids_clothing: preference.separate_kids_clothing,
          sensitive_skin: preference.sensitive_skin,
          remove_pet_hair: preference.remove_pet_hair,
          fold_only: preference.fold_only,
          personal_notes: preference.personal_notes,
          updated_at: preference.updated_at
        }
      end
    end
  end
end
